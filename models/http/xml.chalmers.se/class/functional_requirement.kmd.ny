<?xml version="1.0"?>
<?metis version="5.2.2"?>
<?metisxml version="1.2"?>
<!DOCTYPE metis PUBLIC "-//METIS/METIS XML 1.2//EN" "http://xml.metis.no/metis12.dtd">
<metis
 xmlns="http://www.metis.no/metis"
 xmlns:xlink="http://www.w3.org/1999/xlink"
 types="1"
 typeviews="1"
 nextoid="1">

 <type id="functional_requirement" name="functional_requirement" title="Functional_requirement" usage="object" decomposition-flag="true">
  <complex-type-link xlink:role="type" xlink:title="CC object" xlink:href="cc_object.kmd#CC_object"/>
  <typeview-link xlink:role="typeview" xlink:href="#oid1"/>
  <property name="primary" xlink:role="integer-type" xlink:title="Boolean" xlink:href="metis:std#oid30" label="primary" default-visible="top"/>
  <property name="top" xlink:role="integer-type" xlink:title="Boolean" xlink:href="metis:std#oid30" label="top" default-visible="top"/>
<!--  <part-rule min="0" max="..." xlink:role="type" xlink:title="Design_solution" xlink:href="design_solution.kmd#design_solution"/>
  <named-method-link name="View.onObjectAndViewCreated" xlink:role="cpp-method" xlink:title="createViewAsHierarchy" xlink:href="../methods/cc_methods.kmd#createViewAsHierarchy"/>
  <named-method-link name="View.onObjectAndViewPasted" xlink:role="cpp-method" xlink:title="createViewAsHierarchy" xlink:href="../methods/cc_methods.kmd#createViewAsHierarchy"/> -->
  <valueset vset="default" size="5" xlink:role="type" xlink:title="Functional_requirement" xlink:href="#functional_requirement" xlink:actuate="user">
   <string name="externalID"></string>
   <string name="name"></string>
   <string name="description"></string>
   <integer name="primary">0</integer>
   <integer name="top">0</integer>
  </valueset>
 </type>

 <typeview id="oid1" xlink:role="type" xlink:title="Functional_requirement" xlink:href="#functional_requirement" tree-size="1" nested-size="0.0625" behavior="tree" layout-flags="autolayoutset autolayoutme">
  <layout-link xlink:role="object" xlink:title="CC tree layout" xlink:href="../layout/hierarchy_layout.kmd#_002asgf00sj14lu510jk"/>
  <symbol-override state="open" xlink:role="symbol" xlink:title="box1" xlink:href="../symbols/tree_objects.svg#_002asge01ipf0ancfkjd" xlink:actuate="user">
   <replace tag="text" property="value" macro="(expand &#34;FR: &#34; (property name))"/>
   <replace tag="canvas" property="linecolor" macro="(expand &#34;red&#34;)"/>
  </symbol-override>
  <symbol-override state="closed" xlink:role="symbol" xlink:title="box1" xlink:href="../symbols/tree_objects.svg#_002asge01ipf0ancfkjd" xlink:actuate="user">
   <replace tag="text" property="value" macro="(expand &#34;FR: &#34; (property name))"/>
   <replace tag="canvas" property="linecolor" macro="(expand &#34;red&#34;)"/>
  </symbol-override>
 </typeview>

 <typeview id="oid2" xlink:role="type" xlink:title="Functional_requirement" xlink:href="#functional_requirement" tree-size="0.5" nested-size="0.125" behavior="tree">
  <symbol-override state="open" xlink:role="symbol" xlink:title="Open Object" xlink:href="http://xml.activeknowledgemodeling.com/eka/views/object_tree_open.svg#_002ash401d1mk84cm13r" xlink:actuate="user">
   <replace tag="text" property="value" macro="(expand &#34;FR: &#34; (property name))"/>
   <replace tag="canvas" property="linecolor" macro="(expand &#34;red&#34;)"/>
  </symbol-override>
  <symbol-override state="closed" xlink:role="symbol" xlink:title="Closed Object" xlink:href="metis:stdsyms#oid1" xlink:actuate="user">
   <replace tag="text" property="value" macro="(expand &#34;FR: &#34; (property name))"/>
   <replace tag="canvas" property="linecolor" macro="(expand &#34;red&#34;)"/>
  </symbol-override>
 </typeview>

 <typeview id="oid3" xlink:role="type" xlink:title="Functional_requirement" xlink:href="#functional_requirement" tree-size="0.5" nested-size="0.125" behavior="nested" layout-flags="autolayoutset autolayoutme">
  <symbol-override state="open" xlink:role="symbol" xlink:title="Open Object" xlink:href="metis:stdsyms#oid67" xlink:actuate="user">
   <replace tag="text" property="value" macro="(expand &#34;FR: &#34; (property name))"/>
  </symbol-override>
  <symbol-override state="closed" xlink:role="symbol" xlink:title="Closed Object" xlink:href="metis:stdsyms#oid68" xlink:actuate="user">
   <replace tag="text" property="value" macro="(expand &#34;FR: &#34; (property name))"/>
  </symbol-override>
 </typeview>

 <typeview id="oid4" xlink:role="type" xlink:title="Functional_requirement" xlink:href="#functional_requirement" tree-size="1" nested-size="0.0625" behavior="tree" layout-flags="autolayoutset autolayoutme">
  <layout-link xlink:role="object" xlink:title="CC tree layout" xlink:href="../layout/hierarchy_layout.kmd#_002asgf00sj14lu510jk"/>
  <symbol-override state="open" xlink:role="symbol" xlink:title="box1" xlink:href="../symbols/tree_objects.svg#_002asge01ipf0ancfkjd" xlink:actuate="user">
   <replace tag="text" property="value" macro="(expand &#34;FR: &#34; (property name))"/>
   <replace tag="canvas" property="linecolor" macro="(expand &#34;red&#34;)"/>
  </symbol-override>
  <symbol-override state="closed" xlink:role="symbol" xlink:title="box1" xlink:href="../symbols/tree_objects.svg#_002asge01ipf0ancfkjd" xlink:actuate="user">
   <replace tag="text" property="value" macro="(expand &#34;FR: &#34; (property name))"/>
   <replace tag="canvas" property="linecolor" macro="(expand &#34;red&#34;)"/>
  </symbol-override>
 </typeview>


</metis>
