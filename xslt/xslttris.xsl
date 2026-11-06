<?xml version="1.0" encoding="UTF-8"?>
<!--
  xslttris.xsl - a falling-block puzzle game in XSLT 1.0 (with EXSLT), run by xsltproc.

  An XSLT processor can't read a stream, so the launcher runs this stylesheet once
  per batch of events:

    xsltproc -\-stringparam ev "0 0 1 3 " -\-stringparam out /abs/next.xml state.xml

  The input document is the game state: <s seed="N"/> before the first batch, then
  whatever the previous batch wrote. The stylesheet plays every event in $ev,
  prints a frame for each one that changed something (and one at start-up), and
  writes the new state to $out with exsl:document. When the game ends it prints
  the game-over frame and writes no state, which tells the launcher to stop.
  Event 9 (quit) never gets here: the launcher stops sending at it.

  The rules are the ones in ../SPEC.md.
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:str="http://exslt.org/strings"
    xmlns:t="urn:xslttris"
    extension-element-prefixes="exsl"
    exclude-result-prefixes="str t">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="ev" select="''"/>
  <xsl:param name="out" select="''"/>

  <!-- ===== Tables ========================================================= -->

  <!-- Pieces I O T S Z J L: colour and the four rotation masks (bit y*4+x). -->
  <t:pieces>
    <t:p c="51"><t:r>240</t:r><t:r>17476</t:r><t:r>3840</t:r><t:r>8738</t:r></t:p>
    <t:p c="226"><t:r>102</t:r><t:r>102</t:r><t:r>102</t:r><t:r>102</t:r></t:p>
    <t:p c="135"><t:r>114</t:r><t:r>610</t:r><t:r>624</t:r><t:r>562</t:r></t:p>
    <t:p c="46"><t:r>54</t:r><t:r>1122</t:r><t:r>864</t:r><t:r>561</t:r></t:p>
    <t:p c="196"><t:r>99</t:r><t:r>612</t:r><t:r>1584</t:r><t:r>306</t:r></t:p>
    <t:p c="33"><t:r>113</t:r><t:r>550</t:r><t:r>1136</t:r><t:r>802</t:r></t:p>
    <t:p c="208"><t:r>116</t:r><t:r>1570</t:r><t:r>368</t:r><t:r>547</t:r></t:p>
  </t:pieces>
  <!-- Points for 0-4 cleared rows, before the level multiplier. -->
  <t:points><t:n>0</t:n><t:n>40</t:n><t:n>100</t:n><t:n>300</t:n><t:n>1200</t:n></t:points>
  <!-- Wall kicks tried when rotating, in order. -->
  <t:kicks><t:k>0</t:k><t:k>-1</t:k><t:k>1</t:k><t:k>-2</t:k><t:k>2</t:k></t:kicks>
  <!-- The controls listed in the side panel. -->
  <t:keys>
    <t:k key="← a">move left</t:k><t:k key="→ d">move right</t:k><t:k key="↑ w">rotate</t:k>
    <t:k key="↓ s">soft drop</t:k><t:k key="␣ z">hard drop</t:k><t:k key="  q">quit</t:k>
  </t:keys>

  <xsl:variable name="self" select="document('')/xsl:stylesheet"/>
  <xsl:variable name="P" select="$self/t:pieces/t:p"/>
  <xsl:variable name="POINTS" select="$self/t:points/t:n"/>
  <xsl:variable name="KICKS" select="$self/t:kicks/t:k"/>
  <xsl:variable name="KEYS" select="$self/t:keys/t:k"/>

  <!-- An XML document can't contain the escape character, not even as &#27;.
       str:decode-uri builds it from its URI escape instead. -->
  <xsl:variable name="E" select="str:decode-uri('%1B')"/>
  <xsl:variable name="R" select="concat($E, '[m')"/>
  <xsl:variable name="BC" select="concat($E, '[38;5;60m')"/>   <!-- border colour -->
  <xsl:variable name="DC" select="concat($E, '[38;5;244m')"/>  <!-- dim -->
  <xsl:variable name="W" select="concat($E, '[1m')"/>          <!-- bold -->
  <xsl:variable name="EOL" select="concat($E, '[K&#10;')"/>
  <xsl:variable name="EMPTY" select="str:padding(200, '0')"/>
  <xsl:variable name="TITLE" select="'X S L T T R I S'"/>

  <!-- ===== Driver ========================================================= -->

  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="s/@b">
        <xsl:call-template name="run">
          <xsl:with-param name="st" select="s"/>
          <xsl:with-param name="ev" select="normalize-space($ev)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- First batch: draw the current and the next piece, spawn, draw. -->
        <xsl:variable name="s1" select="s/@seed * 16807 mod 2147483647"/>
        <xsl:variable name="s2" select="$s1 * 16807 mod 2147483647"/>
        <xsl:variable name="raw">
          <s s="{$s2}" b="{$EMPTY}" c="{$s1 mod 7}" n="{$s2 mod 7}" sc="0" ln="0"/>
        </xsl:variable>
        <xsl:variable name="st">
          <xsl:call-template name="spawn">
            <xsl:with-param name="st" select="exsl:node-set($raw)/s"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="frame">
          <xsl:with-param name="st" select="exsl:node-set($st)/s"/>
        </xsl:call-template>
        <xsl:if test="exsl:node-set($st)/s/@o = 0">
          <xsl:call-template name="run">
            <xsl:with-param name="st" select="exsl:node-set($st)/s"/>
            <xsl:with-param name="ev" select="normalize-space($ev)"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Play the space-separated events in $ev one by one, then save the state.
       One recursion level per event: XSLT has no loop that carries state. -->
  <xsl:template name="run">
    <xsl:param name="st"/>
    <xsl:param name="ev"/>
    <xsl:choose>
      <xsl:when test="$ev = ''">
        <exsl:document href="{$out}" method="xml" encoding="UTF-8">
          <xsl:copy-of select="$st"/>
        </exsl:document>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="e" select="number(substring-before(concat($ev, ' '), ' '))"/>
        <xsl:variable name="v">
          <xsl:call-template name="event">
            <xsl:with-param name="st" select="$st"/>
            <xsl:with-param name="e" select="$e"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="ns" select="exsl:node-set($v)/s"/>
        <xsl:if test="$ns/@d = 1">
          <xsl:call-template name="frame">
            <xsl:with-param name="st" select="$ns"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="$ns/@o = 0">
          <xsl:call-template name="run">
            <xsl:with-param name="st" select="$ns"/>
            <xsl:with-param name="ev" select="substring-after($ev, ' ')"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ===== Rules ==========================================================
       State is one element: s seed, b board (200 digits, row 0 first, 0 empty
       or piece+1), c current piece, n next piece, x y r position and rotation,
       t ticks, sc score, ln lines, o game over. Every rule template returns a
       new <s>, built as a copy of the old one with some attributes replaced.
       The event template also sets d="1" when a frame should be drawn. -->

  <xsl:template name="event">
    <xsl:param name="st"/>
    <xsl:param name="e"/>
    <xsl:variable name="m" select="$P[$st/@c + 1]/t:r[$st/@r + 1]"/>
    <xsl:choose>
      <xsl:when test="$e = 0">
        <xsl:variable name="level" select="floor($st/@ln div 10) + 1"/>
        <xsl:variable name="gravity" select="(11 - $level) * (11 - $level &gt; 1) + (11 - $level &lt;= 1)"/>
        <xsl:choose>
          <xsl:when test="$st/@t + 1 &lt; $gravity">
            <s><xsl:copy-of select="$st/@*"/><xsl:attribute name="t"><xsl:value-of select="$st/@t + 1"/></xsl:attribute><xsl:attribute name="d">0</xsl:attribute></s>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="v"><s><xsl:copy-of select="$st/@*"/><xsl:attribute name="t">0</xsl:attribute></s></xsl:variable>
            <xsl:call-template name="step-down">
              <xsl:with-param name="st" select="exsl:node-set($v)/s"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$e = 1 or $e = 2">
        <xsl:variable name="dx" select="2 * $e - 3"/>
        <xsl:variable name="ok">
          <xsl:call-template name="fits">
            <xsl:with-param name="b" select="$st/@b"/>
            <xsl:with-param name="m" select="$m"/>
            <xsl:with-param name="x" select="$st/@x + $dx"/>
            <xsl:with-param name="y" select="$st/@y"/>
          </xsl:call-template>
        </xsl:variable>
        <s><xsl:copy-of select="$st/@*"/><xsl:attribute name="x"><xsl:value-of select="$st/@x + $dx * $ok"/></xsl:attribute><xsl:attribute name="d">1</xsl:attribute></s>
      </xsl:when>
      <xsl:when test="$e = 3">
        <xsl:variable name="nr" select="($st/@r + 1) mod 4"/>
        <xsl:variable name="dx">
          <xsl:call-template name="kick">
            <xsl:with-param name="b" select="$st/@b"/>
            <xsl:with-param name="m" select="$P[$st/@c + 1]/t:r[$nr + 1]"/>
            <xsl:with-param name="x" select="$st/@x"/>
            <xsl:with-param name="y" select="$st/@y"/>
          </xsl:call-template>
        </xsl:variable>
        <s>
          <xsl:copy-of select="$st/@*"/>
          <xsl:if test="$dx != 'none'">
            <xsl:attribute name="x"><xsl:value-of select="$st/@x + $dx"/></xsl:attribute>
            <xsl:attribute name="r"><xsl:value-of select="$nr"/></xsl:attribute>
          </xsl:if>
          <xsl:attribute name="d">1</xsl:attribute>
        </s>
      </xsl:when>
      <xsl:when test="$e = 4">
        <xsl:call-template name="step-down">
          <xsl:with-param name="st" select="$st"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$e = 5">
        <xsl:variable name="y">
          <xsl:call-template name="drop">
            <xsl:with-param name="b" select="$st/@b"/>
            <xsl:with-param name="m" select="$m"/>
            <xsl:with-param name="x" select="$st/@x"/>
            <xsl:with-param name="y" select="$st/@y"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="v"><s><xsl:copy-of select="$st/@*"/><xsl:attribute name="y"><xsl:value-of select="$y"/></xsl:attribute></s></xsl:variable>
        <xsl:call-template name="lock">
          <xsl:with-param name="st" select="exsl:node-set($v)/s"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <s><xsl:copy-of select="$st/@*"/><xsl:attribute name="d">0</xsl:attribute></s>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Move down one row if the piece fits there, otherwise lock it. -->
  <xsl:template name="step-down">
    <xsl:param name="st"/>
    <xsl:variable name="ok">
      <xsl:call-template name="fits">
        <xsl:with-param name="b" select="$st/@b"/>
        <xsl:with-param name="m" select="$P[$st/@c + 1]/t:r[$st/@r + 1]"/>
        <xsl:with-param name="x" select="$st/@x"/>
        <xsl:with-param name="y" select="$st/@y + 1"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$ok = 1">
        <s><xsl:copy-of select="$st/@*"/><xsl:attribute name="y"><xsl:value-of select="$st/@y + 1"/></xsl:attribute><xsl:attribute name="d">1</xsl:attribute></s>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="lock">
          <xsl:with-param name="st" select="$st"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Write the piece into the board, clear full rows, score, take the next piece. -->
  <xsl:template name="lock">
    <xsl:param name="st"/>
    <xsl:variable name="stamped">
      <xsl:call-template name="stamp">
        <xsl:with-param name="b" select="$st/@b"/>
        <xsl:with-param name="m" select="$P[$st/@c + 1]/t:r[$st/@r + 1]"/>
        <xsl:with-param name="x" select="$st/@x"/>
        <xsl:with-param name="y" select="$st/@y"/>
        <xsl:with-param name="v" select="$st/@c + 1"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="kept">
      <xsl:call-template name="keep-rows">
        <xsl:with-param name="b" select="$stamped"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="rows" select="20 - string-length($kept) div 10"/>
    <xsl:variable name="seed" select="$st/@s * 16807 mod 2147483647"/>
    <xsl:variable name="v">
      <s>
        <xsl:copy-of select="$st/@*"/>
        <xsl:attribute name="b"><xsl:value-of select="concat(substring($EMPTY, 1, 200 - string-length($kept)), $kept)"/></xsl:attribute>
        <xsl:attribute name="sc"><xsl:value-of select="$st/@sc + $POINTS[$rows + 1] * (floor($st/@ln div 10) + 1)"/></xsl:attribute>
        <xsl:attribute name="ln"><xsl:value-of select="$st/@ln + $rows"/></xsl:attribute>
        <xsl:attribute name="s"><xsl:value-of select="$seed"/></xsl:attribute>
        <xsl:attribute name="c"><xsl:value-of select="$st/@n"/></xsl:attribute>
        <xsl:attribute name="n"><xsl:value-of select="$seed mod 7"/></xsl:attribute>
      </s>
    </xsl:variable>
    <xsl:call-template name="spawn">
      <xsl:with-param name="st" select="exsl:node-set($v)/s"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Put the current piece at the top; the game is over if it doesn't fit. -->
  <xsl:template name="spawn">
    <xsl:param name="st"/>
    <xsl:variable name="ok">
      <xsl:call-template name="fits">
        <xsl:with-param name="b" select="$st/@b"/>
        <xsl:with-param name="m" select="$P[$st/@c + 1]/t:r[1]"/>
        <xsl:with-param name="x" select="3"/>
        <xsl:with-param name="y" select="0"/>
      </xsl:call-template>
    </xsl:variable>
    <s>
      <xsl:copy-of select="$st/@*"/>
      <xsl:attribute name="x">3</xsl:attribute>
      <xsl:attribute name="y">0</xsl:attribute>
      <xsl:attribute name="r">0</xsl:attribute>
      <xsl:attribute name="t">0</xsl:attribute>
      <xsl:attribute name="o"><xsl:value-of select="1 - $ok"/></xsl:attribute>
      <xsl:attribute name="d">1</xsl:attribute>
    </s>
  </xsl:template>

  <!-- ===== Board helpers ==================================================
       A mask is walked bit by bit: bit i is ($m mod 2) after i halvings,
       and it is cell (i mod 4, i div 4) of the piece's box. -->

  <!-- 1 if mask $m at ($x, $y) lies on the board on empty cells, else 0. -->
  <xsl:template name="fits">
    <xsl:param name="b"/>
    <xsl:param name="m"/>
    <xsl:param name="x"/>
    <xsl:param name="y"/>
    <xsl:param name="i" select="0"/>
    <xsl:variable name="bx" select="$x + $i mod 4"/>
    <xsl:variable name="by" select="$y + floor($i div 4)"/>
    <xsl:choose>
      <xsl:when test="$m = 0">1</xsl:when>
      <xsl:when test="$m mod 2 = 1 and not($bx &gt;= 0 and $bx &lt; 10 and $by &gt;= 0 and $by &lt; 20
                      and substring($b, $by * 10 + $bx + 1, 1) = '0')">0</xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="fits">
          <xsl:with-param name="b" select="$b"/>
          <xsl:with-param name="m" select="floor($m div 2)"/>
          <xsl:with-param name="x" select="$x"/>
          <xsl:with-param name="y" select="$y"/>
          <xsl:with-param name="i" select="$i + 1"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- The board with digit $v written into the cells of mask $m at ($x, $y). -->
  <xsl:template name="stamp">
    <xsl:param name="b"/>
    <xsl:param name="m"/>
    <xsl:param name="x"/>
    <xsl:param name="y"/>
    <xsl:param name="v"/>
    <xsl:param name="i" select="0"/>
    <xsl:choose>
      <xsl:when test="$m = 0"><xsl:value-of select="$b"/></xsl:when>
      <xsl:otherwise>
        <xsl:variable name="at" select="($y + floor($i div 4)) * 10 + $x + $i mod 4"/>
        <xsl:call-template name="stamp">
          <xsl:with-param name="b">
            <xsl:choose>
              <xsl:when test="$m mod 2 = 1"><xsl:value-of select="concat(substring($b, 1, $at), $v, substring($b, $at + 2))"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="$b"/></xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <xsl:with-param name="m" select="floor($m div 2)"/>
          <xsl:with-param name="x" select="$x"/>
          <xsl:with-param name="y" select="$y"/>
          <xsl:with-param name="v" select="$v"/>
          <xsl:with-param name="i" select="$i + 1"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- The rows of $b that still have an empty cell, in order. -->
  <xsl:template name="keep-rows">
    <xsl:param name="b"/>
    <xsl:if test="$b != ''">
      <xsl:if test="contains(substring($b, 1, 10), '0')">
        <xsl:value-of select="substring($b, 1, 10)"/>
      </xsl:if>
      <xsl:call-template name="keep-rows">
        <xsl:with-param name="b" select="substring($b, 11)"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- The lowest y at which mask $m still fits, moving down from $y. -->
  <xsl:template name="drop">
    <xsl:param name="b"/>
    <xsl:param name="m"/>
    <xsl:param name="x"/>
    <xsl:param name="y"/>
    <xsl:variable name="ok">
      <xsl:call-template name="fits">
        <xsl:with-param name="b" select="$b"/>
        <xsl:with-param name="m" select="$m"/>
        <xsl:with-param name="x" select="$x"/>
        <xsl:with-param name="y" select="$y + 1"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$ok = 1">
        <xsl:call-template name="drop">
          <xsl:with-param name="b" select="$b"/>
          <xsl:with-param name="m" select="$m"/>
          <xsl:with-param name="x" select="$x"/>
          <xsl:with-param name="y" select="$y + 1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$y"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- The first wall kick at which mask $m fits, or 'none'. -->
  <xsl:template name="kick">
    <xsl:param name="b"/>
    <xsl:param name="m"/>
    <xsl:param name="x"/>
    <xsl:param name="y"/>
    <xsl:param name="k" select="1"/>
    <xsl:choose>
      <xsl:when test="$k &gt; count($KICKS)">none</xsl:when>
      <xsl:otherwise>
        <xsl:variable name="ok">
          <xsl:call-template name="fits">
            <xsl:with-param name="b" select="$b"/>
            <xsl:with-param name="m" select="$m"/>
            <xsl:with-param name="x" select="$x + $KICKS[$k]"/>
            <xsl:with-param name="y" select="$y"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$ok = 1"><xsl:value-of select="$KICKS[$k]"/></xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="kick">
              <xsl:with-param name="b" select="$b"/>
              <xsl:with-param name="m" select="$m"/>
              <xsl:with-param name="x" select="$x"/>
              <xsl:with-param name="y" select="$y"/>
              <xsl:with-param name="k" select="$k + 1"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ===== Drawing ======================================================== -->

  <xsl:template name="frame">
    <xsl:param name="st"/>
    <!-- the board as drawn: with the falling piece, unless the game is over -->
    <xsl:variable name="grid">
      <xsl:choose>
        <xsl:when test="$st/@o = 1"><xsl:value-of select="$st/@b"/></xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="stamp">
            <xsl:with-param name="b" select="$st/@b"/>
            <xsl:with-param name="m" select="$P[$st/@c + 1]/t:r[$st/@r + 1]"/>
            <xsl:with-param name="x" select="$st/@x"/>
            <xsl:with-param name="y" select="$st/@y"/>
            <xsl:with-param name="v" select="$st/@c + 1"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat($E, '[H  ', $E, '[1;38;5;75m', $TITLE, $R, $EOL)"/>
    <xsl:value-of select="concat(' ', $BC, '╔════════════════════╗', $R, $EOL)"/>
    <xsl:call-template name="rows">
      <xsl:with-param name="st" select="$st"/>
      <xsl:with-param name="grid" select="$grid"/>
    </xsl:call-template>
    <xsl:value-of select="concat(' ', $BC, '╚════════════════════╝', $R, $EOL)"/>
  </xsl:template>

  <!-- Board rows $y..19, each followed by its side-panel text. -->
  <xsl:template name="rows">
    <xsl:param name="st"/>
    <xsl:param name="grid"/>
    <xsl:param name="y" select="0"/>
    <xsl:value-of select="concat(' ', $BC, '║', $R)"/>
    <xsl:choose>
      <xsl:when test="$st/@o = 1 and $y = 9">
        <xsl:value-of select="concat($E, '[1;7m     GAME  OVER     ', $R)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="cells">
          <xsl:with-param name="row" select="substring($grid, $y * 10 + 1, 10)"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="concat($BC, '║', $R)"/>
    <xsl:call-template name="panel">
      <xsl:with-param name="st" select="$st"/>
      <xsl:with-param name="y" select="$y"/>
    </xsl:call-template>
    <xsl:value-of select="$EOL"/>
    <xsl:if test="$y &lt; 19">
      <xsl:call-template name="rows">
        <xsl:with-param name="st" select="$st"/>
        <xsl:with-param name="grid" select="$grid"/>
        <xsl:with-param name="y" select="$y + 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- One board row: an empty cell is a dim dot, a filled one a coloured block. -->
  <xsl:template name="cells">
    <xsl:param name="row"/>
    <xsl:if test="$row != ''">
      <xsl:variable name="c" select="substring($row, 1, 1)"/>
      <xsl:choose>
        <xsl:when test="$c = '0'"><xsl:value-of select="concat($E, '[38;5;237m ·', $R)"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="concat($E, '[38;5;', $P[number($c)]/@c, 'm██', $R)"/></xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="cells">
        <xsl:with-param name="row" select="substring($row, 2)"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="panel">
    <xsl:param name="st"/>
    <xsl:param name="y"/>
    <xsl:choose>
      <xsl:when test="$y = 0">
        <xsl:value-of select="concat('   ', $BC, '╭──', $R, ' ', $DC, 'next', $R, ' ', $BC, '──────╮', $R)"/>
      </xsl:when>
      <xsl:when test="$y = 1 or $y = 6">
        <xsl:value-of select="concat('   ', $BC, '│', $R, '              ', $BC, '│', $R)"/>
      </xsl:when>
      <xsl:when test="$y &gt;= 2 and $y &lt;= 5">
        <!-- box row y-2 of the next piece: mask bits 4(y-2) .. 4(y-2)+3 -->
        <xsl:variable name="by" select="$y - 2"/>
        <xsl:variable name="bits" select="floor($P[$st/@n + 1]/t:r[1] div (1 + 15 * ($by = 1) + 255 * ($by = 2) + 4095 * ($by = 3))) mod 16"/>
        <xsl:value-of select="concat('   ', $BC, '│', $R, '   ')"/>
        <xsl:call-template name="preview">
          <xsl:with-param name="bits" select="$bits"/>
          <xsl:with-param name="block" select="concat($E, '[38;5;', $P[$st/@n + 1]/@c, 'm██', $R)"/>
        </xsl:call-template>
        <xsl:value-of select="concat('   ', $BC, '│', $R)"/>
      </xsl:when>
      <xsl:when test="$y = 7">
        <xsl:value-of select="concat('   ', $BC, '╰──────────────╯', $R)"/>
      </xsl:when>
      <xsl:when test="$y = 9">
        <xsl:value-of select="concat('   ', $DC, 'score', $R)"/>
      </xsl:when>
      <xsl:when test="$y = 10">
        <xsl:value-of select="concat('   ', $W, $st/@sc, $R)"/>
      </xsl:when>
      <xsl:when test="$y = 11">
        <xsl:value-of select="concat('   ', $DC, 'level', $R, ' ', $W, floor($st/@ln div 10) + 1, $R,
                                     '  ', $DC, 'lines', $R, ' ', $W, $st/@ln, $R)"/>
      </xsl:when>
      <xsl:when test="$y = 13">
        <xsl:value-of select="concat('   ', $DC, 'controls', $R)"/>
      </xsl:when>
      <xsl:when test="$y &gt;= 14">
        <xsl:variable name="k" select="$KEYS[$y - 13]"/>
        <xsl:value-of select="concat('   ', $W, $k/@key, $R, '  ', $DC, $k, $R)"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Four preview cells from the low four bits of $bits. -->
  <xsl:template name="preview">
    <xsl:param name="bits"/>
    <xsl:param name="block"/>
    <xsl:param name="i" select="0"/>
    <xsl:if test="$i &lt; 4">
      <xsl:choose>
        <xsl:when test="$bits mod 2 = 1"><xsl:value-of select="$block"/></xsl:when>
        <xsl:otherwise><xsl:text>  </xsl:text></xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="preview">
        <xsl:with-param name="bits" select="floor($bits div 2)"/>
        <xsl:with-param name="block" select="$block"/>
        <xsl:with-param name="i" select="$i + 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
