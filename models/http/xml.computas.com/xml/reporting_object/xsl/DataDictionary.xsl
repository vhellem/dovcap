<?xml version="1.0" ?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="iso-8859-1"
			method="xml"
			omit-xml-declaration="yes"
			indent="yes"
			doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"
			doctype-system="http://www.w3.org/TR/html4/transitional.dtd" />
<xsl:param name="show_toc" 					select="//@show_toc" />
<xsl:param name="use_dhtml_nav" 			select="//@use_dhtml_nav" />
<xsl:param name="show_relationships" 		select="//@show_relationships" />
<xsl:param name="show_parent" 				select="//@show_parent" />
<xsl:param name="show_properties" 			select="//@show_properties" />
<xsl:param name="show_object_details"		select="//@show_object_details" />
<xsl:param name="show_empty_attr" 			select="//@show_empty_attr" />

<xsl:template match="/">
	<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
		<title>Metis Instance Data Dictionary Report</title>
	</head>
	<xsl:call-template name="include_CSS" />
	<xsl:call-template name="include_javascript" />
	<body onload="clearall()">
	<h1 id="top">Metis Instance Data Dictionary Report</h1>
	<!-- Show TOC link -->
	<div id="metisstat" style="display: none; position: absolute;">
		<ul><li><a onclick="switchElem('metismenu', 'metisstat');" href="#">Show table of contents</a></li></ul>
	</div>
	<!-- Table of contents -->
	<xsl:if test="$show_toc = 1">
		<div id="metismenu">
			<ul>
				<xsl:for-each select="metisreport/object">
					<xsl:call-template name="display_TOC" />
				</xsl:for-each>
			</ul>
		</div>
	</xsl:if>
	<!-- Main content -->
	<xsl:for-each select="metisreport/object">
		<xsl:call-template name="display_object" />
	</xsl:for-each>
	<br />
	<div class="footer">Metis Instance Data Dictionary Report</div>
	</body>
	</html>
</xsl:template>

<xsl:template name="display_TOC">
	<xsl:param name="oid" select="generate-id(current())" />
	<xsl:param name="odesc" select="description" />
		<li><a href="#q{$oid}" onclick="val('q{$oid}')" title="{$odesc}"><xsl:value-of select="@name" /></a></li>
		<ul>
			<xsl:for-each select="instances/instance">
				<xsl:if test="@name != ''">
					<li><a href="#w{generate-id(current())}" onclick="val('q{$oid}')"><xsl:value-of select="@name" /></a></li>
				</xsl:if>
			</xsl:for-each>
		</ul>
</xsl:template>

<xsl:template name="display_object">
	<xsl:param name="oid" select="generate-id(current())" />
	<div id="q{$oid}">
		<h2>Object: <xsl:value-of select="@name" /></h2>
		<xsl:if test="$show_object_details = 1">
			<p><xsl:value-of select="description" /></p>
			<xsl:call-template name="object_properties" />
			<span class="small"> &#x2022; <a href="#top" onclick="switchElem('metismenu', 'metisstat');return true;">Go to TOC</a></span>
		</xsl:if>
		<xsl:call-template name="object_instances">
			<xsl:with-param name="oid" select="$oid" />
			<xsl:with-param name="oname" select="@name" />
		</xsl:call-template>
	</div>
</xsl:template>

<xsl:template name="object_properties">
	<h5>Properties</h5>
	<xsl:call-template name="display_properties" />
</xsl:template>

<xsl:template name="object_instances">
	<xsl:param name="oid" />
	<xsl:param name="oname" />
	<xsl:param name="tmp" select="instances/instance" />
	<xsl:if test="$tmp != ''">
	<h3>Instances of <xsl:value-of select="@name" /></h3>
	<div>
		<xsl:for-each select="instances/instance">
			<h4 id="w{generate-id(current())}">
				<xsl:choose>
					<xsl:when test="@name = ''">
						Unnamed instance
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="@name" />
					</xsl:otherwise>
				</xsl:choose>
			</h4>
			<xsl:if test="$show_parent=1 or $show_relationships=1 or $show_properties=1">
				<div class="indent">
					<xsl:call-template name="instance_properties" />
					<xsl:if test="$show_parent = 1">
						<h5>Parent</h5>
						<p><xsl:value-of select="parent" /></p>
					</xsl:if>
					<xsl:if test="$show_relationships = 1">
						<xsl:call-template name="instance_relationships" />
					</xsl:if>
				</div>
				<span class="small"> &#x2022; <a href="#q{$oid}">Go to object <xsl:value-of select="$oname" /></a> &#x2022; <a href="#top" onclick="switchElem('metismenu', 'metisstat');return true;">Go to TOC</a></span>
			</xsl:if>
		</xsl:for-each>
	</div>
	</xsl:if>
</xsl:template>

<xsl:template name="instance_properties">
	<xsl:if test="$show_properties = 1">
		<xsl:call-template name="display_properties" />
	</xsl:if>
</xsl:template>

<xsl:template name="instance_relationships">
	<xsl:param name="rel_c" select="relationships/relationship" />
	<xsl:if test="$rel_c != ''">
		<h5>Relationships</h5>
		<xsl:for-each select="relationships/relationship">
			<p><xsl:value-of select="." /></p>
		</xsl:for-each>
	</xsl:if>
</xsl:template>

<xsl:template name="display_properties">
	<table class="border-table" border="1" cellspacing="1" cellpadding="0">
		<tr>
			<th>Name</th>
			<th>Value</th>
		</tr>
		<xsl:for-each select="properties/*">
			<xsl:call-template name="display_properties_inner" />
		</xsl:for-each>
	</table>
</xsl:template>

<xsl:template name="display_properties_inner">
	<xsl:param name="prop_val" select="." />
	<xsl:param name="prop_name" select="name()" />
	<xsl:param name="prop_label" select="@label" />
	<xsl:if test="$show_empty_attr = 1 or $prop_val != '_EMPTY_'">
		<tr>
			<td nowrap="nowrap">
				<xsl:choose>
					<xsl:when test="$prop_label = '_EMPTY_' or $prop_label = ''">
						<xsl:value-of select="$prop_name" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$prop_label" />
					</xsl:otherwise>
				</xsl:choose>
			</td>
			<td>
				<xsl:choose>
					<xsl:when test="$prop_val != '_EMPTY_' and $prop_val != ''">
						<xsl:value-of select="$prop_val" />
					</xsl:when>
					<xsl:otherwise>
						<span class="inactive">Property has no value</span>
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
	</xsl:if>
</xsl:template>

<xsl:template name="include_javascript">
	<xsl:choose>
		<xsl:when test="$use_dhtml_nav = 1 and $show_toc = 1">
			<script type="text/javascript">
			/* Remove visible elements and show specified element */
		    function val(t)
		    {
					clearall();
					document.getElementById(t).style.display = 'block';
					switchElem('metisstat', 'metismenu');
					document.getElementById(t).style.display = 'block';
					document.getElementById(t).style.position = 'relative';
		    }

		    /* Hide all */
		    function clearall()
		    {
		      var allDivs = document.getElementsByTagName("div");
					for (var y = 0; allDivs[y]; y++)
					{
						if (allDivs[y].id.charAt(0) == 'q')
						{
							allDivs[y].style.display = 'none';
						}
					}
				}

				/* Hide the menu and show the status, and vice versa */
				function switchElem(show_elem, hide_elem)
				{
					document.getElementById(hide_elem).style.display = 'none';
					document.getElementById(hide_elem).style.position = 'absolute';
					document.getElementById(show_elem).style.display = 'block';
					document.getElementById(show_elem).style.position = 'relative';
				}
			</script>
		</xsl:when>
		<xsl:otherwise>
			<script type="text/javascript">
		    function val(t){return true;}
		    function clearall(){return true;}
				function switchElem(show_elem, hide_elem) {return true;}
			</script>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="include_CSS">
	<xsl:choose>
		<xsl:when test="1=1">
			<style type="text/css">
				body, table, tr, td
				{
					font-family: trebuchet ms, arial, helvetica, sans-serif;
					font-size: small;
				}
				.footer
				{
					background: #003366;
					text-align: center;
					margin-top: 15px;
				}
				h1, h2, h3, .footer
				{
					border: 1px solid #336699;
					color: white;
				}
				h1
				{
					background: #003366;
					margin: 5px;
					padding: 5px;
				}
				h2
				{
					background: #336699;
					margin: 5px;
					padding: 5px;
				}
				h3
				{
					background: #6699cc;
					margin: 5px 5px 5px 5px;
					padding-left: 5px;
					font-weight: normal;
				}
				h4
				{
					color: #003366;
					margin-top: 15px;
					margin: 5px 5px 10px 5px;
					padding: 10px 0px 0px 5px;
					font-size: 120%;
				}
				h5
				{
					color: #666666;
					margin-top: 15px;
					margin: 5px;
					padding: 10px 0px 0px 5px;
				}
				a
				{
					color: #003366;
					cursor: hand;
					padding: 0px 2px 1px 2px;
				}
				a:hover
				{
					background: #DCEBF3;
				}
				p
				{
					text-align: justify;
					line-height: 130%;
					margin: 3px;
					padding: 0px 15px 0px 15px;
				}
				.border-table
				{
					border: 0px;
					background: #999999;
					margin: 0px 15px 5px 15px;
				}
				.border-table td
				{
					border: 0px;
					background: white;
				}
				.border-table th
				{
					border: 0px;
					color: black;
					background: #dddddd;
				}
				th, td
				{
					padding-left: 5px;
					padding-right: 5px;
				}
				.inactive
				{
					color: #ccc;
				}
				.indent, .small
				{
					padding: 0px 15px 0px 15px;
					margin-top: 15px;
				}
				.small a
				{
					font-size: x-small;
					color: gray;
					margin-right: 10px;
				}
			</style>
		</xsl:when>
	</xsl:choose>
</xsl:template>
</xsl:transform>