<?xml version="1.0" encoding="UTF-8"?>
<!-- ***************************************************************************
*  (c) 2010 by Basler Vision Technologies
*  Section: Vision Components
*  Project: GenApi
*  Author:  Fritz Dierks
******************************************************************************** -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

	<xsl:output method="text" encoding="UTF-8"/>	
	<xsl:template match="/">
		//-----------------------------------------------------------------------------
		//  (c) 2010 by Basler Vision Technologies
		//  Section: Vision Components
		//  Project: GenApi
		//	Author:  Fritz Dierks
		//-----------------------------------------------------------------------------
		/*!
			\file     <xsl:value-of select="//Root/@Name"/>.dot
		*/
		//-----------------------------------------------------------------------------
		//  This file is generated automatically
		//  Do not modify!
		//-----------------------------------------------------------------------------

		digraph GenApi 
		{
			<xsl:apply-templates select="/*/*" mode="ListNodes"/>
			<xsl:apply-templates select="/*/*" mode="Connections"/>
		}	
	</xsl:template>
	
	<!-- ListNodes ******************************************** -->

	<xsl:template  match="*" mode="ListNodes">
		<xsl:value-of select="@Name"/> [label="<xsl:value-of select="name()"/>::<xsl:value-of select="@Name"/>"];
	</xsl:template>

	<!-- Connections ******************************************** -->

	<xsl:template  match="*" mode="Connections">
		<xsl:apply-templates select="./*" mode="InsideConnections"/>
	</xsl:template>
	
	<xsl:template  match="*" mode="InsideConnections">
	    <!-- Show all links except those  created by the postporcessor -->
		<xsl:if test="starts-with(name(), 'p') and not(name()='pTerminal') and not(name()='pDependent')">
			<xsl:value-of select="../@Name"/> -> <xsl:value-of select="."/> [label="<xsl:value-of select="name()"/>"];
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
