(:
This file is part of SynopsX.
    created by AHN team (http://ahn.ens-lyon.fr)
    release 0.1, 2014-01-28
    
SynopsX is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

SynopsX is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with SynopsX.  
If not, see <http://www.gnu.org/licenses/>
:)
    
module namespace synopsx = 'http://ahn.ens-lyon.fr/synopsx';
declare namespace db = 'http://basex.org/modules/db';
declare namespace xslt="http://basex.org/modules/xslt";
declare namespace xf="http://www.w3.org/2002/xforms";


import module namespace synopsx_html = 'http://ahn.ens-lyon.fr/synopsx_html' at 'synopsx_html.xqm';
(:import module namespace ahn = 'http://ahn.ens-lyon.fr/ahn' at 'ahn.xqm';
:)
(:import module namespace ahn_commons_html = 'http://ahn.ens-lyon.fr/ahn_commons_html' at 'ahn_commons_html.xqm';:)
(:import module namespace desanti = 'http://ahn.ens-lyon.fr/desanti' at 'desanti.xqm';:)



(: import module namespace synodes = 'http://ahn.ens-lyon.fr/synodes' at 'synodes.xqm'; :)

(: 
this function checks if the specified output type has been assigned to a specific namespace for this project
this information stands in the config.xml file
:)
declare function synopsx:get_namespace($project_name, $output_type){
  string(db:open('config')//*[@name=$project_name]//output[1]/@value)
};


(: This function checks whether there is a customization of the generic-templating function. 
By default, synopsX function is called. :)
declare function synopsx:function-lookup($function_name, $project_name, $output_type){
  (:TODO : make the inheritage process recursive :)
  
  let $function := 
  if(db:exists($project_name)) then
  
  
  
        let $ns := synopsx:get_namespace($project_name,$output_type)
        
   
        let $specific := if($ns = "") then () else function-lookup(xs:QName($ns || ":" || $function_name),1)
        (: Check if the module declares a parent module :)
        let $parent_module := string(db:open('config')//*[@name=$project_name]//parent[1]/@value)
        (:let $parent_module := string(db:open("config",$project_name||".xml")//*[@name="parent_module"][1]/@value):)
        (: Checks if the declared parent module has a customization of the generic-templating function :)
        let $parent := if ($parent_module = "") then ()
                else function-lookup(xs:QName(synopsx:get_namespace($parent_module,$output_type)|| ":" || $function_name),1)
        let $generic := function-lookup(xs:QName(synopsx:get_namespace("synopsx",$output_type) ||":" || $function_name),1)
  
        let $f :=
            if (not(empty($specific))) then $specific
            else if (not(empty($parent))) then $parent
            else if  (not(empty($generic))) then  $generic
            else function-lookup(xs:QName("synopsx_html:notFound"),1)
        return $f
        
     
     
     
     
     else function-lookup(xs:QName("synopsx:no-database"),1)
     
     return $function
};


declare function synopsx:no-database($params) {
	<html>
	<head><title>Base {map:get($params,"project")} not found</title></head>
	<body>
	   <header>SynopsX</header>
	   <p>No database found for "{map:get($params,"project")}"
	   <br/>{map:get($params,"dataType")}
	   <br/>{map:get($params,"value")}
	   <br/>{map:get($params,"option")}
	   </p>
	   <p>You have to <a href="/{map:get($params,"project")}/create-database">create a database</a> first.</p>
	   <footer>Synopsx is brought to you by Atelier des Humanités Numériques - ENS de Lyon</footer>
	</body>
	</html>
};



declare %restxq:path("{$project_name}/create-database/")
        %output:method("xml")
          %output:omit-xml-declaration("yes")
 updating function synopsx:create-database($project_name) {

(if(db:exists($project_name)) then () else db:create($project_name),
            db:output(<restxq:redirect>/{$project_name}/db-exists/</restxq:redirect>))  
};


declare %restxq:path("{$project_name}/db-exists/")
        %output:method("html")
          %output:omit-xml-declaration("yes")
function synopsx:db-exists($project_name) { 
<html>
	<head><title>Start your project {$project_name} now !</title></head>
	<body>
	   <header>SynopsX</header>
<section>Add xml data to your database {$project_name} and 
<br/><a href="/{$project_name}/config">configure your synopsx webapp</a></section>
</body>
</html>
};

declare %restxq:path("{$project_name}/config/")
        %output:method("xml")
          %output:omit-xml-declaration("yes")
updating function synopsx:db-config($project_name) { 
let $config := <configuration name="{$project_name}">
<parent value="synopsx"/>
<ouput name="html" value="synopsx_html"/>
<output name="oai" value="synopsx_oai"/>
<head/>
</configuration>
 return (db:add("config", $config, $project_name||".xml"),
  db:output(<restxq:redirect>/{$project_name}</restxq:redirect>))
};




declare updating function synopsx:initialize() { 
            (db:create("config"),
            db:output(<restxq:redirect>synopsx/config/</restxq:redirect>)) 
};

