<?xml version="1.0"?>
<!--
    This file is part of qa-reports

    Copyright (C) 2012 Milosz Wasilewski <milosz.wasilewski@gmail.com>
    Copyright (C) 2012 Jolla Ltd.
    Contact: Reto Zingg <reto.zingg@jollamobile.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
  <html>
    <head>
      <title>Test Results</title>
      <style type="text/css">
        *{
          font-family: sans-serif;
          color: black;
        }

        pre{
          font-family: monospace;
          font-size: large;
        }

        #testsuite {
          padding-left: 10px;
          padding-right: 10px;
          border: solid black 1px;
          margin: 5px;
        }

        #testset {
          padding-left: 10px;
          padding-right: 10px;
          margin: 5px;
          border: solid blue 1px;
        }

        #presteps {
          padding-left: 10px;
          padding-right: 10px;
          margin: 5px;
          border: solid yellow 1px;
        }

        #testcase {
          padding-left: 10px;
          padding-right: 10px;
          margin: 5px;
          border: solid 1px;
        }

        .teststep {
          padding-left: 10px;
          padding-right: 10px;
          margin: 5px;
          border: solid 1px;
          background-color: white;
        }

        .stdout {
          padding-left: 10px;
          padding-right: 10px;
          border: dashed #90EE90 2px;
        }

        .stderr {
          padding-left: 10px;
          padding-right: 10px;
          border: dashed #FF4500 2px;
        }

        .PASS {
          border-color: #90EE90;
          background-color: #90EE90;
        }

        .FAIL {
          border-color: #FF4500;
          background-color: #FF4500;
        }

        .stepscontainer {
          display: none;
        }
      </style>
      <script>
        function switch_display(element) {
          e = document.getElementById(element)
          if (e.style.display == "none") {
            e.style.display = "block"
          } else {
            e.style.display = "none"
          }
        }
      </script>
    </head>
    <body>
      Total: <xsl:value-of select="count(/testresults/suite/set/case)"/> | Pass: <xsl:value-of select="count(/testresults/suite/set/case[@result='PASS'])"/> | Fail: <xsl:value-of select="count(/testresults/suite/set/case[@result='FAIL'])"/>
      <xsl:apply-templates/>
    </body>
  </html>
</xsl:template>

<xsl:template match="suite">
  <div id="testsuite">
    Name: <xsl:value-of select="@name"/> | Domain <xsl:value-of select="@domain"/>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="set">
  <div id="testset">
    Name: <xsl:value-of select="@name"/> | Domain: <xsl:value-of select="@domain"/> | Feature: <xsl:value-of select="@feature"/> | Description: <xsl:value-of select="description"/>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="pre_steps">
  <div id="presteps">
    <a href="#" onclick="switch_display('pre_steps')">+</a>Pre-steps
    <div class="stepscontainer" id="pre_steps">
      <xsl:apply-templates/>
    </div>
  </div>
</xsl:template>

<xsl:template match="post_steps">
  <div id="presteps">
    <a href="#" onclick="switch_display('post_steps')">+</a>Post-steps
    <div class="stepscontainer" id="post_steps">
      <xsl:apply-templates/>
    </div>
  </div>
</xsl:template>

<xsl:template match="case">
  <xsl:variable name="case_id"><xsl:value-of select="@name"/></xsl:variable>
  <div id="testcase" class="{@result}"> <a href="#" onclick="switch_display('{$case_id}')">+</a>
    Name: <xsl:value-of select="@name"/> | Result: <xsl:value-of select="@result"/> | Start: <xsl:value-of select="@start"/> | Duration: <xsl:value-of select="@duration"/> | Accept ID: <xsl:value-of select="@accept_id"/>
    <div id="{$case_id}" style="display:none">
      <xsl:apply-templates>
        <xsl:with-param name="tc_name" select="@name"/>
      </xsl:apply-templates>
    </div>
  </div>
</xsl:template>

<xsl:template match="step">
  <div class="teststep">
    Command: <xsl:value-of select="@command"/> <br/>
    Result: <xsl:value-of select="@result"/> <br/>
    Expected result: <xsl:value-of select="expected_result"/> <br/>
    Return code:<xsl:value-of select="return_code"/> <br/>
    Start: <xsl:value-of select="start"/><br/>
    End: <xsl:value-of select="end"/><br/>
    Duration: <xsl:value-of select="duration"/><br/>
    <div class="stdout">
      <pre>
        <xsl:value-of select="stdout"/>
      </pre>
    </div>
    <br/>
    <div class="stderr">
      <pre>
        <xsl:value-of select="stderr"/>
      </pre>
    </div>
  </div>
</xsl:template>

<xsl:template match="get">
</xsl:template>

<xsl:template match="description">
</xsl:template>

</xsl:stylesheet>
