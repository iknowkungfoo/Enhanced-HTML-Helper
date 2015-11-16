<cfcomponent name="htmlHelper"
			 hint="This is the enhanced htmlHelper plugin."
			 extends="coldbox.system.plugins.htmlHelper"
			 output="false"
			 cache="true">

	<!--- --------------------------------------------------------------------------------- --->
	<!--- NOTE: Cannot issue logging commands from this interceptor, doesn't extend base.baseInterceptor --->
	<!--- --------------------------------------------------------------------------------- --->
	<!--- NOTE:  This is only an EXTENSION/OVERRIDE of the existing messageBox plugin to  --->
	<!--- 	provide additional message types (info, error, warning and now: success --->
	<!--- --------------------------------------------------------------------------------- --->

	<cffunction name="init" access="public" returntype="htmlHelper" output="false" hint="Constructor">
		<cfargument name="controller" type="any" required="true" hint="coldbox.system.controller">
		<cfscript>
			super.Init(arguments.controller);
			setpluginName("HTMLHelperEnhanced");
			setpluginVersion("1.0");
			setpluginDescription("A cool utility that helps you when working with HTML, using OWASP Encoders for enhanced security.");
			setpluginAuthor("Adrian J. Moreno");
			setpluginAuthorURL("http://iknowkungfoo.com");
			return this;
		</cfscript>
	</cffunction>

	<!--- ******************** Copied from ColdBox 4.0 HTMLHelper.cfc ******************************** --->

	<cffunction name="tag" output="false" access="public" returntype="any" hint="Surround content with a tag">
		<cfargument name="tag" 			type="string" required="true"	hint="The tag to generate"/>
		<cfargument name="content"		type="string" required="false" default=""	hint="The content of the tag"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var buffer	= createObject("java","java.lang.StringBuffer").init( "<#arguments.tag#" );

			// append tag attributes
			flattenAttributes( arguments, "tag,content", buffer ).append( '>#encodeForHTML(arguments.content)#</#arguments.tag#>' );

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="anchor" output="false" access="public" returntype="any" hint="Create an anchor tag">
		<cfargument name="name" 	 	type="any" 		required="true" 	hint="The name of the anchor"/>
		<cfargument name="text" 	 	type="any" 		required="false" default="" 	hint="The text of the link"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var buffer 		= createObject("java","java.lang.StringBuffer").init("<a");

			// build link
			flattenAttributes( arguments, "text", buffer ).append( '>#encodeForHTML(arguments.text)#</a>' );

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="href" output="false" access="public" returntype="any" hint="Create href tags, using the SES base URL or not">
		<cfargument name="href" 	 	type="any" 		required="false" 	default="" hint="Where to link to, this can be an action, absolute, etc"/>
		<cfargument name="text" 	 	type="any" 		required="false"		default="" hint="The text of the link"/>
		<cfargument name="queryString"	type="any"		required="false"		default="" hint="The query string to append, if needed.">
		<cfargument name="title"	 	type="any" 		required="false" 	default="" hint="The title attribute"/>
		<cfargument name="target"	 	type="any" 		required="false" 	default="" hint="The target of the href link"/>
		<cfargument name="ssl" 			type="boolean" 	required="false" 	default="false" hint="If true, it will change http to https if found in the ses base url ONLY"/>
		<cfargument name="noBaseURL" 	type="boolean" 	required="false" 	default="false" hint="Defaults to false. If you want to NOT append a request's ses or html base url then set this argument to true"/>
		<cfargument name="img"			type="struct" required="false" default="#structNew()#"	hint="Defines an img for the content of the href instead of text. Supercedes text argument."/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var buffer 	= createObject("java","java.lang.StringBuffer").init("<a");
			var event	= controller.getRequestService().getContext();

			// self-link?
			if(NOT len(arguments.href) ){
				arguments.href = event.getCurrentEvent();
			}

			// Check if we have a base URL and if we need to build our link
			if( arguments.noBaseURL eq FALSE and NOT find("://",arguments.href)){
				arguments.href = event.buildLink(linkto=arguments.href,ssl=arguments.ssl,queryString=arguments.queryString);
			}

			// build link
			if (!structIsEmpty(arguments.img)) {
				flattenAttributes(arguments,"noBaseURL,text,querystring,ssl",buffer).append('>' & this.img(argumentCollection = arguments.img) & '</a>');
			} else {
				flattenAttributes(arguments,"noBaseURL,text,querystring,ssl",buffer).append('>#encodeForHTML(arguments.text)#</a>');
			}

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="link" output="false" access="public" returntype="any" hint="Create link tags, using the SES base URL or not">
		<cfargument name="href" 	 	type="any" 		required="true" hint="The href link to link to"/>
		<cfargument name="rel" 		 	type="any"		required="false"	default="stylesheet" hint="The rel attribute"/>
		<cfargument name="type" 	 	type="any"		required="false" 	default="text/css" hint="The type attribute"/>
		<cfargument name="title"	 	type="any" 		required="false" 	default="" hint="The title attribute"/>
		<cfargument name="media" 	 	type="any"		required="false" 	default="" hint="The media attribute"/>
		<cfargument name="noBaseURL" 	type="boolean" 	required="false" 	default="false" hint="Defaults to false. If you want to NOT append a request's ses or html base url then set this argument to true"/>
		<cfargument name="charset" 		type="any" 		required="false" 	default="UTF-8" hint="The charset to add, defaults to utf-8"/>
		<cfargument name="sendToHeader" type="boolean"	required="false" 	default="false" hint="Send to the header via htmlhead by default, else it returns the content"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var buffer 		= createObject("java","java.lang.StringBuffer").init("<link");

			// Check if we have a base URL
			arguments.href = prepareBaseLink(arguments.noBaseURL,arguments.href);

			//exclusions
			local.excludes = "noBaseURL";
			if(structKeyExists(arguments,'rel')){
				if(arguments.rel == "canonical"){
					local.excludes &= ",type,title,media,charset";
				}
			}

			// build link
			flattenAttributes(arguments,local.excludes,buffer).append('/>');

			//Load it
			if( arguments.sendToHeader AND len(buffer.toString())){
				$htmlhead(buffer.toString());
			}
			else{
				return buffer.toString();
			}
		</cfscript>
	</cffunction>

	<cffunction name="img" output="false" access="public" returntype="any" hint="Create image tags using the SES base URL or not">
		<cfargument name="src" 		 type="any" 	required="true" hint="The source URL to link to"/>
		<cfargument name="alt" 		 type="string"	required="false" default="" hint="The alt tag"/>
		<cfargument name="class" 	 type="string"	required="false" default="" hint="The class tag"/>
		<cfargument name="width" 	 type="string"	required="false" default="" hint="The width tag"/>
		<cfargument name="height"		type="string"	required="false" default="" hint="The height tag"/>
		<cfargument name="title" 	 type="string"	required="false" default="" hint="The title tag"/>
		<cfargument name="rel" 		 type="string"	required="false" default="" hint="The rel tag"/>
		<cfargument name="name" 	 type="string"	required="false" default="" hint="The name tag"/>
		<cfargument name="noBaseURL" type="boolean" required="false" default="false" hint="Defaults to false. If you want to NOT append a request's ses or html base url then set this argument to true"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var buffer = createObject("java","java.lang.StringBuffer").init("<img");

			// ID Normalization
			normalizeID(arguments);

			// Check if we have a base URL
			arguments.src = prepareBaseLink(arguments.noBaseURL, arguments.src);

			// create image
			flattenAttributes(arguments,"noBaseURL",buffer).append(' />');

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="meta" output="false" access="public" returntype="any" hint="Helps you generate meta tags">
		<cfargument name="name" 	type="any" 		required="true" hint="A name for the meta tag or an array of struct data to convert to meta tags.Keys [name,content,type]"/>
		<cfargument name="content" 	type="any" 		required="false" default="" hint="The content attribute"/>
		<cfargument name="type" 	type="string"	 required="false" default="name" hint="Either ''name'' or ''equiv'' which produces http-equiv instead of the name"/>
		<cfargument name="sendToHeader" type="boolean"	required="false" default="false" hint="Send to the header via htmlhead by default, else it returns the content"/>
		<cfscript>
			var x 		= 1;
			var buffer	= createObject("java","java.lang.StringBuffer").init("");
			var tmpType = "";

			// prep type
			if( arguments.type eq "equiv" ){ arguments.type = "http-equiv"; };

			// Array of structs or simple value
			if( isSimpleValue(arguments.name) ){
				buffer.append('<meta #arguments.type#="#encodeForHTMLAttribute(arguments.name)#" content="#encodeForHTMLAttribute(arguments.content)#" />');
			}

			if(isArray(arguments.name)){
				for(x=1; x lte arrayLen(arguments.name); x=x+1 ){
					if( NOT structKeyExists(arguments.name[x], "type") ){
						arguments.name[x].type = "name";
					}
					if(	arguments.name[x].type eq "equiv" ){
						arguments.name[x].type = "http-equiv";
					}

					buffer.append('<meta #arguments.name[x].type#="#encodeForHTMLAttribute(arguments.name[x].name)#" content="#encodeForHTMLAttribute(arguments.name[x].content)#" />');
				}
			}

			//Load it
			if( arguments.sendToHeader AND len(buffer.toString())){
				$htmlhead(buffer.toString());
			}
			else{
				return buffer.toString();
			}
		</cfscript>
	</cffunction>

	<cffunction name="autoDiscoveryLink" output="false" access="public" returntype="any" hint="Creates auto discovery links for RSS and ATOM feeds.">
		<cfargument name="type" 		type="string" 	required="false" default="RSS" hint="Type of feed: RSS or ATOM or Custom Type"/>
		<cfargument name="href" 	 	type="any" 		required="false" hint="The href link to discover"/>
		<cfargument name="rel" 		 	type="any"		required="false" default="alternate" hint="The rel attribute"/>
		<cfargument name="title"	 	type="any" 		required="false" default="" hint="The title attribute"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var buffer	= createObject("java","java.lang.StringBuffer").init("<link");

			// type: determination
			switch(arguments.type){
				case "rss"	: { arguments.type = "application/rss+xml";	break;}
				case "atom" : { arguments.type = "application/atom+xml"; break;}
				default 	: { arguments.type = arguments.type; }
			}

			// create link
			flattenAttributes(arguments,"",buffer).append('/>');

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="video" output="false" access="public" returntype="any" hint="Create an HTML 5 video tag">
		<cfargument name="src" 		 type="any" 	required="true" hint="The source URL or array or list of URL's to create video tags for"/>
		<cfargument name="width" 	 type="string"	required="false" default="" hint="The width tag"/>
		<cfargument name="height"		type="string"	required="false" default="" hint="The height tag"/>
		<cfargument name="poster"		 type="string"	required="false" default="" hint="The URL of the image when video is unavailable"/>
		<cfargument name="autoplay"	type="boolean" required="false" default="false" hint="Whether or not to start playing the video as soon as it can"/>
		<cfargument name="controls"	type="boolean" required="false" default="true" hint="Whether or not to show controls on the video player"/>
		<cfargument name="loop"		 type="boolean" required="false" default="false" hint="Whether or not to loop the video over and over again"/>
		<cfargument name="preload"	 type="boolean" required="false" default="false" hint="If true, the video will be loaded at page load, and ready to run. Ignored if 'autoplay' is present"/>
		<cfargument name="noBaseURL" type="boolean" required="false" default="false" hint="Defaults to false. If you want to NOT append a request's ses or html base url then set this argument to true"/>
		<cfargument name="name" 	 type="string"	required="false" default="" hint="The name tag"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var video 		= createObject("java","java.lang.StringBuffer").init("<video");
			var x			= 1;

			// autoplay diff
			if( arguments.autoplay ){ arguments.autoplay = "autoplay";}
			else{ arguments.autoplay = "";}
			// controls diff
			if( arguments.controls ){ arguments.controls = "controls";}
			else{ arguments.controls = "";}
			// loop diff
			if( arguments.loop ){ arguments.loop = "loop";}
			else{ arguments.loop = "";}
			// preLoad diff
			if( arguments.preLoad ){ arguments.preLoad = "preload";}
			else{ arguments.preLoad = "";}

			// src array check
			if( isSimpleValue(arguments.src) ){ arguments.src = listToArray(arguments.src); }

			// ID Normalization
			normalizeID(arguments);

			// create video tag
			flattenAttributes(arguments,"noBaseURL,src",video);

			// Add single source
			if( arrayLen(arguments.src) eq 1){
				arguments.src[1] = prepareBaseLink(arguments.noBaseURL, arguments.src[1]);
				video.append(' src="#arguments.src[1]#" />');
				return video.toString();
			}

			// create source tags
			video.append(">");
			for(x=1; x lte arrayLen(arguments.src); x++){
				arguments.src[x] = prepareBaseLink(arguments.noBaseURL, arguments.src[x]);
				video.append('<source src="#arguments.src[x]#"/>');
			}
			video.append("</video>");

			return video.toString();
		</cfscript>
	</cffunction>

	<cffunction name="audio" output="false" access="public" returntype="any" hint="Create an HTML 5 audio tag">
		<cfargument name="src" 		 type="any" 	required="true" hint="The source URL or array or list of URL's to create audio tags for"/>
		<cfargument name="autoplay"	type="boolean" required="false" default="false" hint="Whether or not to start playing the audio as soon as it can"/>
		<cfargument name="controls"	type="boolean" required="false" default="true" hint="Whether or not to show controls on the audio player"/>
		<cfargument name="loop"		 type="boolean" required="false" default="false" hint="Whether or not to loop the audio over and over again"/>
		<cfargument name="preLoad"	 type="boolean" required="false" default="false" hint="If true, the audio will be loaded at page load, and ready to run. Ignored if 'autoplay' is present"/>
		<cfargument name="noBaseURL" type="boolean" required="false" default="false" hint="Defaults to false. If you want to NOT append a request's ses or html base url then set this argument to true"/>
		<cfargument name="name" 	 type="string"	required="false" default="" hint="The name tag"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var audio 		= createObject("java","java.lang.StringBuffer").init("<audio");
			var x			= 1;

			// autoplay diff
			if( arguments.autoplay ){ arguments.autoplay = "autoplay";}
			else{ arguments.autoplay = "";}
			// controls diff
			if( arguments.controls ){ arguments.controls = "controls";}
			else{ arguments.controls = "";}
			// loop diff
			if( arguments.loop ){ arguments.loop = "loop";}
			else{ arguments.loop = "";}
			// preLoad diff
			if( arguments.preLoad ){ arguments.preLoad = "preload";}
			else{ arguments.preLoad = "";}

			// src array check
			if( isSimpleValue(arguments.src) ){ arguments.src = listToArray(arguments.src); }

			// ID Normalization
			normalizeID(arguments);

			// create video tag
			flattenAttributes(arguments,"noBaseURL,src",audio);

			// Add single source
			if( arrayLen(arguments.src) eq 1){
				arguments.src[1] = prepareBaseLink(arguments.noBaseURL, arguments.src[1]);
				audio.append(' src="#arguments.src[1]#" />');
				return audio.toString();
			}

			// create source tags
			audio.append(">");
			for(x=1; x lte arrayLen(arguments.src); x++){
				arguments.src[x] = prepareBaseLink(arguments.noBaseURL, arguments.src[x]);
				audio.append('<source src="#arguments.src[x]#"/>');
			}
			audio.append("</audio>");

			return audio.toString();
		</cfscript>
	</cffunction>

	<cffunction name="canvas" output="false" access="public" returntype="any" hint="Create a canvas tag">
		<cfargument name="id" 		 type="string"	required="true"	hint="The id of the canvas"/>
		<cfargument name="width" 	 type="string"	required="false" default="" hint="The width tag"/>
		<cfargument name="height"		type="string"	required="false" default="" hint="The height tag"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var canvas 		= createObject("java","java.lang.StringBuffer").init("<canvas");

			// create canvas tag
			flattenAttributes(arguments,"",canvas).append("></canvas>");

			return canvas.toString();
		</cfscript>
	</cffunction>

	<cffunction name="startForm" output="false" access="public" returntype="any" hint="Create cool form tags. Any extra argument will be passed as attributes to the form tag">
		<cfargument name="action" 		type="string" 	required="false" 	default="" hint="The event or route action to submit to.	This will be inflated using the request's base URL if not a full http URL. If empty, then it is a self-submitting form"/>
		<cfargument name="name" 		type="string" 	required="false" 	default="" hint="The name of the form tag"/>
		<cfargument name="method" 		type="string" 	required="false" 	default="POST" 	hint="The HTTP method of the form: POST or GET"/>
		<cfargument name="multipart" 	type="boolean" 	required="false" 	default="false"	hint="Set the multipart encoding type on the form"/>
		<cfargument name="ssl" 			type="boolean" 	required="false" 	default="false" hint="If true, it will change http to https if found in the ses base url ONLY"/>
		<cfargument name="noBaseURL" 	type="boolean" 	required="false" 	default="false" hint="Defaults to false. If you want to NOT append a request's ses or html base url then set this argument to true"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var formBuffer	= createObject("java","java.lang.StringBuffer").init("<form");
			var event 		= controller.getRequestService().getContext();

			// self-submitting?
			if(NOT len(arguments.action) ){
				arguments.action = event.getCurrentEvent();
			}

			// Check if we have a base URL and if we need to build our link
			if( arguments.noBaseURL eq FALSE and NOT find("://",arguments.action)){
				arguments.action = event.buildLink(linkto=arguments.action,ssl=arguments.ssl);
			}

			// ID Normalization
			normalizeID(arguments);

			// Multipart Encoding Type
			if( arguments.multipart ){ arguments.enctype = "multipart/form-data"; }
			else{ arguments.enctype = "";}

			// create tag
			flattenAttributes(arguments,"noBaseURL,ssl,multipart",formBuffer).append(">");

			return formBuffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="startFieldset" output="false" access="public" returntype="any" hint="Create a fieldset tag with or without a legend.">
		<cfargument name="legend" 		type="string" 	required="false" 	default="" hint="The legend to use (if any)"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var buffer = createObject("java","java.lang.StringBuffer").init('<fieldset');

			// fieldset attributes
			flattenAttributes(arguments,"legend",buffer).append(">");

			// add Legend?
			if( len(arguments.legend) ){
				buffer.append("<legend>#encodeForHTML(arguments.legend)#</legend>");
			}

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="label" access="public" returntype="any" output="false" hint="Render a label tag. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="field" 		type="string" required="true"	hint="The for who attribute"/>
		<cfargument name="content" 		type="string" required="false" default="" hint="The label content. If not passed the field is used"/>
		<cfargument name="wrapper" 		type="string" required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfargument name="class"		type="string" required="false" default="" hint="The class to be applied to the label">
		<cfscript>
			var buffer = createObject("java","java.lang.StringBuffer").init('');

			// wrapper?
			wrapTag(buffer,arguments.wrapper);

			// get content
			if( NOT len(content) ){ arguments.content = makePretty(arguments.field); }
			arguments.for = arguments.field;

			// create label tag
			buffer.append("<label");
			flattenAttributes(arguments,"content,field,wrapper",buffer).append(">#encodeForHTML(arguments.content)#</label>");

			//wrapper?
			wrapTag(buffer,arguments.wrapper,1);

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="textArea" access="public" returntype="any" output="false" hint="Render out a textarea. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the textarea"/>
		<cfargument name="cols" 		type="numeric" 	required="false" hint="The number of columns"/>
		<cfargument name="rows" 		type="numeric" 	required="false" hint="The number of rows"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the textarea"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="readonly" 	type="boolean" 	required="false" default="false" hint="Readonly"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="bind" 		type="any" 		required="false" default="" hint="The entity binded to this control, the value comes by convention from the name attribute"/>
		<cfargument name="bindProperty" type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var buffer = createObject("java","java.lang.StringBuffer").init('');

			// ID Normalization
			normalizeID(arguments);
			// group wrapper?
			wrapTag(buffer,arguments.groupWrapper);
			// label?
			if( len(arguments.label) ){ buffer.append( this.label(field=arguments.id,content=arguments.label,wrapper=arguments.labelWrapper,class=arguments.labelClass) ); }

			//wrapper?
			wrapTag(buffer,arguments.wrapper);

			// disabled fix
			if( arguments.disabled ){ arguments.disabled = "disabled"; }
			else{ arguments.disabled = ""; }
			// readonly fix
			if( arguments.readonly ){ arguments.readonly = "readonly"; }
			else{ arguments.readonly = ""; }

			// Entity Binding?
			bindValue(arguments);

			// create textarea
			buffer.append("<textarea");
			flattenAttributes(arguments,"value,label,wrapper,labelWrapper,groupWrapper,labelClass,bind,bindProperty",buffer).append(">#encodeForHTML(arguments.value)#</textarea>");

			//wrapper?
			wrapTag(buffer,arguments.wrapper,1);
			// group wrapper?
			wrapTag(buffer,arguments.groupWrapper,1);
			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="passwordField" access="public" returntype="any" output="false" hint="Render out a password field. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="readonly" 	type="boolean" 	required="false" default="false" hint="Readonly"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="bind" 		type="any" 		required="false" default="" hint="The entity binded to this control"/>
		<cfargument name="bindProperty" type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<cfscript>
			arguments.type="password";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- urlfield --->
	<cffunction name="urlfield" access="public" returntype="any" output="false" hint="Render out a URL field. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="readonly" 	type="boolean" 	required="false" default="false" hint="Readonly"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="bind" 		type="any" 		required="false" default="" hint="The entity binded to this control"/>
		<cfargument name="bindProperty" type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<cfscript>
			arguments.type="url";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- emailField --->
	<cffunction name="emailField" access="public" returntype="any" output="false" hint="Render out an email field. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="readonly" 	type="boolean" 	required="false" default="false" hint="Readonly"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="bind" 		type="any" 		required="false" default="" hint="The entity binded to this control"/>
		<cfargument name="bindProperty" type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<cfscript>
			arguments.type="email";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- hiddenField --->
	<cffunction name="hiddenField" access="public" returntype="any" output="false" hint="Render out a hidden field. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the field"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="bind" 		type="any" 		required="false" default="" hint="The entity binded to this control"/>
		<cfargument name="bindProperty" type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<cfscript>
			arguments.type="hidden";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- textField --->
	<cffunction name="textField" access="public" returntype="any" output="false" hint="Render out a text field. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="readonly" 	type="boolean" 	required="false" default="false" hint="Readonly"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="bind" 		type="any" 		required="false" default="" hint="The entity binded to this control"/>
		<cfargument name="bindProperty" type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<cfscript>
			arguments.type="text";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- button --->
	<cffunction name="button" access="public" returntype="any" output="false" hint="Render out a button. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled button or not?"/>
		<cfargument name="type" 		type="string"	 required="false" default="button" hint="The type of button to create: button, reset or submit"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfscript>
			var buffer = createObject("java","java.lang.StringBuffer").init('');

			// ID Normalization
			normalizeID(arguments);
			// group wrapper?
			wrapTag(buffer,arguments.groupWrapper);
			// label?
			if( len(arguments.label) ){ buffer.append( this.label(field=arguments.id,content=arguments.label,wrapper=arguments.labelWrapper,class=arguments.labelClass) ); }

			//wrapper?
			wrapTag(buffer,arguments.wrapper);

			// disabled fix
			if( arguments.disabled ){ arguments.disabled = "disabled"; }
			else{ arguments.disabled = ""; }

			// create textarea
			buffer.append("<button");
			flattenAttributes(arguments,"value,label,wrapper,labelWrapper,groupWrapper,labelClass",buffer).append(">#encodeForHTML(arguments.value)#</button>");

			//wrapper?
			wrapTag(buffer,arguments.wrapper,1);
			// group wrapper?
			wrapTag(buffer,arguments.groupWrapper,1);
			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="altButton" access="public" returntype="any" output="false" hint="Render out a button. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled button or not?"/>
		<cfargument name="type" 		type="string"	 required="false" default="button" hint="The type of button to create: button, reset or submit"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<!--- Bootstrap settings --->
		<cfargument name="element"		type="string"	required="false" default="button" hint="Bootstrap button type: <a>, <button> or <input>." />
		<cfargument name="style" 		type="string"	required="false" default="default" hint="Bootstrap button style option." />
		<cfargument name="size" 		type="string"	required="false" default=""	hint="Boostrap button size option." />
		<cfargument name="block" 		type="boolean"	required="false" default="false"	hint="Bootstrap button block option." />
		<cfargument name="active" 		type="boolean"	required="false" default="false"	hint="Bootstrap button active option." />
		<cfargument name="link" 		type="string"	required="false" default=""	hint="Where to link to, this can be an action, absolute, etc."/>
		<cfscript>
			if ( refindnocase("(link|button)", arguments.element) EQ 0 ) {
				throw(message = "Invalid value for HTML Helper altButton argument element (#arguments.element#).", type="htmlHelper");
			}
			if ( refindnocase("(default|primary|success|info|warning|danger|link)", arguments.style) EQ 0 ) {
				throw(message = "Invalid value for HTML Helper altButton argument style (#arguments.element#).", type="htmlHelper");
			}
			if ( len(arguments.size ) GT 0 ) {
				if ( refindnocase("(big|small|tiny)", arguments.size) EQ 0 ) {
					throw(message = "Invalid value for HTML Helper altButton argument size (#arguments.element#).", type="htmlHelper");
				} else {
					switch(arguments.size){
						case "big":
							arguments.size = "lg";
							break;
						case "small":
							arguments.size = "sm";
							break;
						case "tiny":
							arguments.size = "xs";
							break;
					}
				}
			}
			var config = {
				element = arguments.element
				, style = arguments.style
				, size = arguments.size
				, block = arguments.block
				, active = arguments.active
			};
			structDelete(arguments, "element");
			structDelete(arguments, "style");
			structDelete(arguments, "size");
			structDelete(arguments, "block");
			structDelete(arguments, "active");
			arguments.class = "btn";
			arguments.class = listAppend(arguments.class, "btn-" & config.style, " ");
			if (len(config.size) GT 0) {
				arguments.class = listAppend(arguments.class, "btn-" & config.size, " ");
			}
			if (config.block) {
				arguments.class = listAppend(arguments.class, "btn-block", " ");
			}
			if (config.active) {
				arguments.class = listAppend(arguments.class, "active", " ");
			}

			switch(config.element) {
				case "link":
					arguments.role = "button";
					if (arguments.disabled) {
						arguments.class = listAppend(arguments.class, "disabled", " ");
					}
					structDelete(arguments, "disabled");
					if (len(arguments.value)) {
						arguments.text = arguments.value;
						structDelete(arguments, "value");
					}
					var args = arguments;
					args.href = arguments.link;
					structDelete(args, link);
					return variables.href(argumentCollection = args);
					break;

				default:
					if (config.active) {
						arguments.aria.pressed = true;
					}
					return variables.button(argumentCollection = arguments);
					break;
			}

		</cfscript>



	</cffunction>

	<!--- fileField --->
	<cffunction name="fileField" access="public" returntype="any" output="false" hint="Render out a file field. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="readonly" 	type="boolean" 	required="false" default="false" hint="Readonly"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfscript>
			arguments.type="file";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- checkBox --->
	<cffunction name="checkBox" access="public" returntype="any" output="false" hint="Render out a checkbox. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="true" hint="The value of the field, defaults to true"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="checked" 		type="boolean" 	required="false" default="false" hint="Checked"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="bind" 		type="any" 		required="false" default="" hint="The entity binded to this control"/>
		<cfargument name="bindProperty" type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<cfscript>
			arguments.type="checkbox";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- radioButton --->
	<cffunction name="radioButton" access="public" returntype="any" output="false" hint="Render out a radio button. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="true" hint="The value of the field, defaults to true"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="checked" 		type="boolean" 	required="false" default="false" hint="Checked"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="bind" 		type="any" 		required="false" default="" hint="The entity binded to this control"/>
		<cfargument name="bindProperty" type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<cfscript>
			arguments.type="radio";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- submitButton --->
	<cffunction name="submitButton" access="public" returntype="any" output="false" hint="Render out a submit button. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="Submit" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfscript>
			arguments.type="submit";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- resetButton --->
	<cffunction name="resetButton" access="public" returntype="any" output="false" hint="Render out a reset button. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="Reset" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfscript>
			arguments.type="reset";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<!--- imageButton --->
	<cffunction name="imageButton" access="public" returntype="any" output="false" hint="Render out a image button. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="src" 			type="string"	required="true"	hint="The image src"/>
		<cfargument name="name" 		type="string" 	required="false" default=""	hint="The name of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfscript>
			arguments.type="image";
			return inputField(argumentCollection=arguments);
		</cfscript>
	</cffunction>

	<cffunction name="select" access="public" returntype="any" output="false" hint="Render out a select tag. Remember that any extra arguments are passed as tag attributes">
		<cfargument name="name" 			type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="options" 			type="any"		required="false" default="" hint="The value for the options, usually by calling our options() method"/>
		<!--- option arguments --->
		<cfargument name="column" 			type="string" 	required="false" default=""	hint="If using a query or array of objects the column to display as value and name"/>
		<cfargument name="nameColumn" 		type="string" 	required="false" default=""	hint="If using a query or array of objects, the name column to display, if not passed defaults to the value column"/>
		<cfargument name="selectedIndex" 	type="numeric" 	required="false" default="0" hint="selected index"/>
		<cfargument name="selectedValue" 	type="string" 	required="false" default="" hint="selected value if any"/>
		<cfargument name="excludedValues" 	type="string" 	required="false" default="" hint="A CSV list of option values to exclude from the 'values' column." />
		<cfargument name="bind" 			type="any" 		required="false" default="" hint="The entity binded to this control"/>
		<cfargument name="bindProperty"	 	type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<!--- html arguments --->
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled button or not?"/>
		<cfargument name="multiple" 	type="boolean" 	required="false" default="false" hint="multiple button or not?"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="size" 		type="numeric" 	required="false" default="5" hint="If multiple = true, how many rows to display." />

		<cfscript>
			var buffer = createObject("java","java.lang.StringBuffer").init('');
			if (!arguments.multiple) {
				structDelete(arguments, "size");
			}

			// ID Normalization
			normalizeID(arguments);
			// group wrapper?
			wrapTag(buffer,arguments.groupWrapper);
			// label?
			if( len(arguments.label) ){ buffer.append( this.label(field=arguments.id,content=arguments.label,wrapper=arguments.labelWrapper,class=arguments.labelClass) ); }

			//wrapper?
			wrapTag(buffer,arguments.wrapper);

			// disabled fix
			if( arguments.disabled ){ arguments.disabled = "disabled"; }
			else{ arguments.disabled = ""; }
			// multiple fix
			if( arguments.multiple ){ arguments.multiple = "multiple"; }
			else{ arguments.multiple = ""; }

			// create select
			buffer.append("<select");
			flattenAttributes(arguments,"options,column,nameColumn,selectedIndex,selectedValue,bind,bindProperty,label,wrapper,labelWrapper,groupWrapper,labelClass,verbose,allOption",buffer).append(">");

			// binding of option
			bindValue(arguments);
			if( structKeyExists(arguments,"value") AND len(arguments.value) ){
				arguments.selectedValue = arguments.value;
			}

			// options, are they inflatted already or do we inflate
			if( isSimpleValue(arguments.options) AND findnocase("</option>",arguments.options) ){
				buffer.append( arguments.options );
			}
			else{
				buffer.append( this.options(arguments.options,arguments.column,arguments.nameColumn,arguments.selectedIndex,arguments.selectedValue,arguments.excludedValues) );
			}

			// finalize select
			buffer.append("</select>");

			//wrapper?
			wrapTag(buffer,arguments.wrapper,1);
			// group wrapper?
			wrapTag(buffer,arguments.groupWrapper, 1);

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="inputField" output="false" access="public" returntype="any" hint="Create an input field using some cool tags and features.	Any extra arguments are passed to the tag">
		<cfargument name="type" 		type="string"	 required="false" default="text" hint="The type of input field to create"/>
		<cfargument name="name" 		type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="value" 		type="string"	required="false" default="" hint="The value of the field"/>
		<cfargument name="disabled" 	type="boolean" 	required="false" default="false" hint="Disabled"/>
		<cfargument name="checked" 		type="boolean" 	required="false" default="false" hint="Checked"/>
		<cfargument name="readonly" 	type="boolean" 	required="false" default="false" hint="Readonly"/>
		<cfargument name="wrapper" 		type="string" 	required="false" default="" hint="The wrapper tag to use around the tag. Empty by default">
		<cfargument name="groupWrapper" type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="label" 		type="string"	required="false" default="" hint="If Passed we will prepend a label tag"/>
		<cfargument name="labelwrapper" type="string"	required="false" default="" hint="The wrapper tag to use around the label. Empty by default"/>
		<cfargument name="labelClass" 	type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="bind" 		type="any" 		required="false" default="" hint="The entity binded to this control"/>
		<cfargument name="bindProperty" type="any" 		required="false" default="" hint="The property to use for the value, by convention we use the name attribute"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var buffer 		= createObject( "java", "java.lang.StringBuffer" ).init( '' );
			var excludeList = "label,wrapper,labelWrapper,groupWrapper,labelClass,bind,bindProperty";

			// ID Normalization
			normalizeID( arguments );
			// group wrapper?
			wrapTag( buffer, arguments.groupWrapper );
			// label?
			if( len( arguments.label ) ){ buffer.append( this.label( field=arguments.id, content=arguments.label, wrapper=arguments.labelWrapper, class=arguments.labelClass ) ); }
			//wrapper?
			wrapTag( buffer, arguments.wrapper );

			// disabled fix
			if( arguments.disabled ){ arguments.disabled = "disabled"; }
			else{ arguments.disabled = ""; }
			// checked fix
			if( arguments.checked ){ arguments.checked = "checked"; }
			else{ arguments.checked = ""; }
			// readonly fix
			if( arguments.readonly ){ arguments.readonly = "readonly"; }
			else{ arguments.readonly = ""; }

			// binding?
			bindValue( arguments );

			// create textarea
			buffer.append("<input");
			flattenAttributes( arguments, excludeList, buffer ).append( "/>" );

			//wrapper?
			wrapTag( buffer, arguments.wrapper, 1 );
			// group wrapper?
			wrapTag( buffer, arguments.groupWrapper, 1 );

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="entityFields" output="false" access="public" returntype="any" hint="Create fields based on entity properties">
		<cfargument name="entity" 			type="any" 		required="true" hint="The entity binded to this control"/>
		<cfargument name="groupWrapper" 	type="string" 	required="false" default="" hint="The wrapper tag to use around the tag and label. Empty by default">
		<cfargument name="fieldwrapper" 	type="any"		required="false" default="" hint="The wrapper tag to use around the field items. Empty by default"/>
		<cfargument name="labelwrapper" 	type="any"		required="false" default="" hint="The wrapper tag to use around the label items. Empty by default"/>
		<cfargument name="labelClass" 		type="string"	required="false" default="" hint="The class to be applied to the label"/>
		<cfargument name="textareas" 		type="any"		required="false" default="" hint="A list of property names that you want as textareas"/>
		<cfargument name="booleanSelect" 	type="boolean" 	required="false" default="true" hint="If a boolean is detected a dropdown is generated, if false, then radio buttons"/>
		<cfargument name="showRelations" 	type="boolean" 	required="false" default="true" hint="If true it will show relation tables for one to one and one to many"/>
		<cfargument name="manytoone" 		type="struct" 	required="false" default="#structnew()#" hint="A structure of data to help with many to one relationships on how they are presented. Possible key values for each key are [valuecolumn='',namecolumn='',criteria={},sortorder=string]. Example: {criteria={productid=1},sortorder='Department desc'}"/>
		<cfargument name="manytomany" 		type="struct" 	required="false" default="#structnew()#" hint="A structure of data to help with many to one relationships on how they are presented. Possible key values for each key are [valuecolumn='',namecolumn='',criteria={},sortorder=string,selectColumn='']. Example: {criteria={productid=1},sortorder='Department desc'}"/>
		<cfscript>
			var buffer 	= createObject("java","java.lang.StringBuffer").init('');
			var md 		= getMetadata( arguments.entity );
			var x		= 1;
			var y		= 1;
			var prop	= "";
			var args	= {};
			var loc		= {};

			// if no properties just return.
			if( NOT structKeyExists(md,"properties") ){ return ""; }

			// iterate properties array
			for(x=1; x lte arrayLen(md.properties); x++ ){
				prop = md.properties[x];

				// setup some defaults
				loc.persistent 	= true;
				loc.ormtype		= "string";
				loc.fieldType	= "column";
				loc.insert		= true;
				loc.update		= true;
				loc.formula		= "";
				loc.readonly	= false;
				if( structKeyExists(prop,"persistent") ){ loc.persistent = prop.persistent; }
				if( structKeyExists(prop,"ormtype") ){ loc.ormtype = prop.ormtype; }
				if( structKeyExists(prop,"fieldType") ){ loc.fieldType = prop.fieldType; }
				if( structKeyExists(prop,"insert") ){ loc.insert = prop.insert; }
				if( structKeyExists(prop,"update") ){ loc.update = prop.update; }
				if( structKeyExists(prop,"formula") ){ loc.formula = prop.formula; }
				if( structKeyExists(prop,"readonly") ){ loc.readonly = prop.readonly; }

				// html 5 data items
				arguments["data-ormtype"] 	= loc.ormtype;
				arguments["data-insert"] 	= loc.insert;
				arguments["data-update"] 	= loc.update;

				// continue on non-persistent ones or formulas or readonly
				loc.orm = ORMGetSession();
				if( NOT loc.persistent OR len(loc.formula) OR loc.readOnly OR
					( loc.orm.contains(arguments.entity) AND NOT loc.update ) OR
					( NOT loc.orm.contains(arguments.entity) AND NOT loc.insert )
				){ continue; }

				switch(loc.fieldType){
					//primary key as hidden field
					case "id" : {
						args = {
							name=prop.name,bind=arguments.entity
						};
						buffer.append( hiddenField(argumentCollection=args) );
						break;
					}
					case "many-to-many" : {
						// prepare lookup args
						loc.criteria			= {};
						loc.sortorder 		= "";
						loc.column 			= "";
						loc.nameColumn 		= "";
						loc.selectColumn 	= "";
						loc.values			= [];
						loc.relArray		= [];
						arguments["data-ormtype"] 	= "many-to-many";

						// is key found in manytoone arg
						if( structKeyExists(arguments.manytomany, prop.name) ){
							if( structKeyExists(arguments.manytomany[prop.name],"valueColumn") ){ loc.column = arguments.manytomany[prop.name].valueColumn; }
							else{
								throw(message="The 'valueColumn' property is missing from the '#prop.name#' relationship data, which is mandatory",
									   detail="A structure of data to help with many to one relationships on how they are presented. Possible key values for each key are [valuecolumn='',namecolumn='',criteria={},sortorder=string,selectColumn='']. Example: {criteria={productid=1},sortorder='Department desc'}",
									   type="EntityFieldsInvalidRelationData");
							}
							if( structKeyExists(arguments.manytomany[prop.name],"nameColumn") ){ loc.nameColumn = arguments.manytomany[prop.name].nameColumn; }
							else{
								loc.nameColumn = arguments.manytomany[prop.name].valueColumn;
							}
							if( structKeyExists(arguments.manytomany[prop.name],"criteria") ){ loc.criteria = arguments.manytomany[prop.name].criteria; }
							if( structKeyExists(arguments.manytomany[prop.name],"sortorder") ){ loc.sortorder = arguments.manytomany[prop.name].sortorder; }
							if( structKeyExists(arguments.manytomany[prop.name],"selectColumn") ){ loc.selectColumn = arguments.manytomany[prop.name].selectColumn; }
						}
						else{
							throw(message="There is no many to many information for the '#prop.name#' relationship in the entityFields() arguments.  Please make sure you create one",
								  detail="A structure of data to help with many to one relationships on how they are presented. Possible key values for each key are [valuecolumn='',namecolumn='',criteria={},sortorder=string,selectColumn='']. Example: {criteria={productid=1},sortorder='Department desc'}",
								  type="EntityFieldsInvalidRelationData");
						}

						// values should be an array of objects, so let's convert them
						loc.relArray = evaluate("arguments.entity.get#prop.name#()");
						if( isNull(loc.relArray) ){ loc.relArray = []; }
						if( NOT len(loc.selectColumn) AND arrayLen(loc.relArray) ){
							// if select column is empty, then select first property as select value, not perfect but hey better than nothing
							loc.selectColumn = getMetadata( loc.relArray[1] ).properties[1].name;
						}
						// iterate and select
						for(y=1; y lte arrayLen(loc.relArray); y++){
							arrayAppend(loc.values, evaluate("loc.relArray[y].get#loc.selectColumn#()") );
						}
						// generation args
						args = {
							name=prop.name, options=entityLoad( prop.cfc, loc.criteria, loc.sortorder ), column=loc.column, nameColumn=loc.nameColumn,
							multiple=true, label=prop.name, labelwrapper=arguments.labelWrapper, labelClass=arguments.labelClass, wrapper=arguments.fieldwrapper,
							groupWrapper=arguments.groupWrapper, selectedValue=arrayToList( loc.values )
						};
						structAppend(args,arguments);
						buffer.append( this.select(argumentCollection=args) );
						break;
					}
					// one to many display
					case "one-to-many" : {
						loc.orm = ORMGetSession();
						// A new or persisted entity? If new, then skip out
						if( NOT loc.orm.contains(arguments.entity) OR NOT arguments.showRelations){
							break;
						}
						arguments["data-ormtype"] 	= "one-to-many";
						// We just show them as a nice table because we are not scaffolding, just display
						// values should be an array of objects, so let's convert them
						loc.relArray = evaluate("arguments.entity.get#prop.name#()");
						if( isNull(loc.relArray) ){ loc.relArray = []; }

						// Label Generation
						args = {
							field=prop.name, wrapper=arguments.labelWrapper, class=arguments.labelClass
						};
						structAppend(args,arguments);
						buffer.append( this.label(argumentCollection=args) );

						// Table Generation
						if( arrayLen(loc.relArray) ){
							args = {
								name=prop.name, data=loc.relArray
							};
							structAppend(args,arguments);
							buffer.append( this.table(argumentCollection=args) );
						}
						else{
							buffer.append("<p>None Found</p>");
						}

						break;
					}
					// one to many display
					case "one-to-one" : {
						loc.orm = ORMGetSession();
						// A new or persisted entity? If new, then skip out
						if( NOT loc.orm.contains(arguments.entity) OR NOT arguments.showRelations){
							break;
						}

						arguments["data-ormtype"] 	= "one-to-one";
						// We just show them as a nice table because we are not scaffolding, just display
						// values should be an array of objects, so let's convert them
						loc.data = evaluate("arguments.entity.get#prop.name#()");
						if( isNull(loc.data) ){ loc.relArray = []; }
						else{ loc.relArray = [ loc.data ]; }

						// Label Generation
						args = {
							field=prop.name, wrapper=arguments.labelWrapper, class=arguments.labelClass
						};
						structAppend(args,arguments);
						buffer.append( this.label(argumentCollection=args) );

						// Table Generation
						if( arrayLen(loc.relArray) ){
							args = {
								name=prop.name, data=loc.relArray
							};
							structAppend(args,arguments);
							buffer.append( this.table(argumentCollection=args) );
						}
						else{
							buffer.append("<p>None Found</p>");
						}
						break;
					}
					// many to one
					case "many-to-one" : {
						arguments["data-ormtype"] 	= "many-to-one";
						// prepare lookup args
						loc.criteria	= {};
						loc.sortorder = "";
						loc.column = "";
						loc.nameColumn = "";
						// is key found in manytoone arg
						if( structKeyExists(arguments.manytoone, prop.name) ){
							// Verify the valueColumn which is mandatory
							if( structKeyExists(arguments.manytoone[prop.name],"valueColumn") ){ loc.column = arguments.manytoone[prop.name].valueColumn; }
							else{
								throw(message="The 'valueColumn' property is missing from the '#prop.name#' relationship data, which is mandatory",
									   detail="A structure of data to help with many to one relationships on how they are presented. Possible key values for each key are [valuecolumn='',namecolumn='',criteria={},sortorder=string]. Example: {criteria={productid=1},sortorder='Department desc'}",
									   type="EntityFieldsInvalidRelationData");
							}
							if( structKeyExists(arguments.manytoone[prop.name],"nameColumn") ){ loc.nameColumn = arguments.manytoone[prop.name].nameColumn; }
							else { loc.nameColumn = arguments.manytoone[prop.name].valueColumn; }
							if( structKeyExists(arguments.manytoone[prop.name],"criteria") ){ loc.criteria = arguments.manytoone[prop.name].criteria; }
							if( structKeyExists(arguments.manytoone[prop.name],"sortorder") ){ loc.sortorder = arguments.manytoone[prop.name].sortorder; }
						}
						else{
							throw(message="There is no many to one information for the '#prop.name#' relationship in the entityFields() arguments.  Please make sure you create one",
								  detail="A structure of data to help with many to one relationships on how they are presented. Possible key values for each key are [valuecolumn='',namecolumn='',criteria={},sortorder=string]. Example: {criteria={productid=1},sortorder='Department desc'}",
								  type="EntityFieldsInvalidRelationData");
						}
						// generation args
						args = {
							name=prop.name, options=entityLoad( prop.cfc, loc.criteria, loc.sortorder ),
							column=loc.column, nameColumn=loc.nameColumn,
							label=prop.name, bind=arguments.entity, labelwrapper=arguments.labelWrapper, labelClass=arguments.labelClass,
							wrapper=arguments.fieldwrapper, groupWrapper=arguments.groupWrapper
						};
						structAppend(args,arguments);
						buffer.append( this.select(argumentCollection=args) );
						break;
					}
					// columns
					case "column" : {

						// booleans?
						if( structKeyExists(prop,"ormtype") and prop.ormtype eq "boolean"){
							// boolean select or radio buttons
							if( arguments.booleanSelect ){
								args = {
									name=prop.name, options=[true,false], label=prop.name, bind=arguments.entity, labelwrapper=arguments.labelWrapper, labelClass=arguments.labelClass,
									wrapper=arguments.fieldwrapper, groupWrapper=arguments.groupWrapper
								};
								structAppend(args,arguments);
								buffer.append( this.select(argumentCollection=args) );
							}
							else{
								args = {
									name=prop.name, value="true", label="True", bind=arguments.entity, labelwrapper=arguments.labelWrapper, labelClass=arguments.labelClass,
									groupWrapper=arguments.groupWrapper, wrapper=arguments.fieldWrapper
								};
								structAppend(args,arguments);
								buffer.append( this.radioButton(argumentCollection=args) );
								args.value="false";
								args.label="false";
								buffer.append( this.radioButton(argumentCollection=args) );
							}
							continue;
						}
						// text args
						args = {
							name=prop.name, label=prop.name, bind=arguments.entity, labelwrapper=arguments.labelWrapper, labelClass=arguments.labelClass,
							wrapper=arguments.fieldwrapper, groupWrapper=arguments.groupWrapper
						};
						structAppend(args,arguments);
						// text and textarea fields
						if( len(arguments.textareas) AND listFindNoCase(arguments.textareas, prop.name) ){
							buffer.append( this.textarea(argumentCollection=args) );
						}
						else{
							buffer.append( this.textfield(argumentCollection=args) );
						}
					}// end case column

				}// end switch

			}// end for loop

			return buffer.toString();
		</cfscript>
	</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------>

	<!--- arrayToTable --->
	<cffunction name="arrayToTable" output="false" access="private" returntype="void" hint="Convert a table out of an array">
		<cfargument name="data" 		type="any"			 required="true"	hint="The array to convert into a table"/>
		<cfargument name="includes" 	type="string"		required="false" default=""	hint="The columns to include in the rendering"/>
		<cfargument name="excludes" 	type="string"		required="false" default=""	hint="The columns to exclude in the rendering"/>
		<cfargument name="buffer" 		type="any" 	 	 required="true"/>
		<cfscript>
			var str		= arguments.buffer;
			var attrs	= "";
			var x		= 1;
			var y		= 1;
			var key		= "";
			var cols	= structKeyArray( data[ 1 ] );

			// Render Headers
			for(x=1; x lte arrayLen(cols); x=x+1){
				// Display?
				if( passIncludeExclude(cols[x],arguments.includes,arguments.excludes) ){
					str.append("<th>#encodeForHTML(cols[x])#</th>");
				}
			}
			str.append("</tr></thead>");

			// Render Body
			str.append("<tbody>");
			for(x=1; x lte arrayLen(arguments.data); x=x+1){
				str.append("<tr>");
				for(y=1; y lte arrayLen(cols); y=y+1){
					// Display?
					if( passIncludeExclude(cols[y],arguments.includes,arguments.excludes) ){
						str.append("<td>#encodeForHTML(arguments.data[x][cols[y]])#</td>");
					}
				}
				str.append("</tr>");
			}
		</cfscript>
	</cffunction>

	<!--- queryToTable --->
	<cffunction name="queryToTable" output="false" access="private" returntype="void" hint="Convert a table out of an array of structures">
		<cfargument name="data" 		type="any"			 required="true"	hint="The query to convert into a table"/>
		<cfargument name="includes" 	type="string"		required="false" default=""	hint="The columns to include in the rendering"/>
		<cfargument name="excludes" 	type="string"		required="false" default=""	hint="The columns to exclude in the rendering"/>
		<cfargument name="buffer" 		type="any" 	 	 required="true"/>
		<cfscript>
			var str		= arguments.buffer;
			var cols	 = listToArray(arguments.data.columnList);
			var x			= 1;
			var y		 = 1;

			// Render Headers
			for(x=1; x lte arrayLen(cols); x=x+1){
				// Display?
				if( passIncludeExclude(cols[x],arguments.includes,arguments.excludes) ){
					str.append("<th>#encodeForHTML(cols[x])#</th>");
				}
			}
			str.append("</tr></thead>");

			// Render Body
			str.append("<tbody>");
			for(x=1; x lte arguments.data.recordcount; x=x+1){
				str.append("<tr>");
				for(y=1; y lte arrayLen(cols); y=y+1){
					// Display?
					if( passIncludeExclude(cols[y],arguments.includes,arguments.excludes) ){
						str.append("<td>#encodeForHTML(arguments.data[cols[y]][x])#</td>");
					}
				}
				str.append("</tr>");
			}
		</cfscript>
	</cffunction>

	<!--- toHTMLList --->
	<cffunction name="toHTMLList" output="false" access="private" returntype="any" hint="Convert a sent in tag type to an HTML list">
		<cfargument name="tag"	 		type="string" required="true" hint="The list tag type"/>
		<cfargument name="values" 		type="any"		required="true" default="" hint="An array of values or list of values"/>
		<cfargument name="column"		 	type="string" required="false" default="" hint="If the values is a query, this is the name of the column to get the data from to create the list"/>
		<cfargument name="data"			type="struct" required="false" default="#structNew()#"	hint="A structure that will add data-{key} elements to the HTML control"/>
		<cfscript>
			var val 	= arguments.values;
			var x	 	= 1;
			var str 	= createObject("java","java.lang.StringBuffer").init("");
			var br		= chr(13);
			var args	= "";

			// list or array or query?
			if( isSimpleValue(val) ){ val = listToArray(val); }
			if( isQuery(val) ){ val = getColumnArray(val,arguments.column); }

			// start tag
			str.append("<#arguments.tag#");
			// flatten extra attributes via arguments
			flattenAttributes(arguments,"tag,values,column",str).append(">");

			// values
			for(x=1; x lte arrayLen(val); x=x+1){

				if( isArray(val[x]) ){
					str.append( toHTMLList(arguments.tag,val[x],arguments.column) );
				}
				else{
					str.append("<li>#encodeForHTML(val[x])#</li>");
				}

			}

			str.append("</#arguments.tag#>");
			return str.toString();
		</cfscript>
	</cffunction>

	<!--- bindValue --->
	<cffunction name="bindValue" output="false" access="private" returntype="any" hint="Bind entity values">
		<cfargument name="args">
		<cfscript>
			var entityValue = "";

			// binding?
			if( isObject( arguments.args.bind ) ){
				// do we have a bindProperty, else default it from the name
				if( NOT len( arguments.args.bindProperty ) ){

					// check if name exists else throw exception
					if( NOT structKeyExists( arguments.args, "name" ) OR NOT len( arguments.args.name ) ){
						throw( type="HTMLHelper.NameBindingException", message="The 'name' argument was not passed and not binding property was passed, so we can't bind dude!" );
					}

					// bind name property
					arguments.args.bindProperty = arguments.args.name;
				}

				// entity value
				entityValue = evaluate( "arguments.args.bind.get#arguments.args.bindProperty#()" );
				if( isNull( entityValue ) ){ entityValue = ""; }
				// Verify if the value is an entity, if it is, then use the 'column' to retrieve the value
				if( isObject( entityValue ) ){ entityValue = evaluate( "entityValue.get#arguments.args.column#()" ); }

				// If radio or checkbox button, check it
				if( structKeyExists( arguments.args, "type" ) AND listFindNoCase( "radio,checkbox", arguments.args.type ) ){
					// is incoming value eq to property value with boolean aspects
					if( structKeyExists( arguments.args, "value" ) and
					    isBoolean( arguments.args.value ) and
					    yesNoFormat( arguments.args.value ) EQ yesNoFormat( entityValue ) ){
						arguments.args.checked = true;
					}
					// else with no boolean evals
					else if( structKeyExists( arguments.args, "value" ) and arguments.args.value EQ entityValue ){
						arguments.args.checked = true;
					}
				}
				else{
					// If there is no incoming value, then bind it
					arguments.args.value = entityValue;
				}
			}
		</cfscript>
	</cffunction>

	<!--- onMissingMethod --->
    <cffunction name="onMissingMethod" output="false" access="public" returntype="any" hint="Proxy calls to provided element">
    	<cfargument	name="missingMethodName"		required="true"	hint="missing method name"	/>
		<cfargument	name="missingMethodArguments" 	required="true"	hint="missing method arguments"/>

    	<!---Incorporate tag to args --->
    	<cfset missingMethodArguments.tag = arguments.missingMethodName>

		<!--- Do Content --->
		<cfif structKeyExists(arguments.missingMethodArguments, 1)>
			<cfset arguments.missingMethodArguments.content = arguments.missingMethodArguments.1>
			<cfset structdelete( arguments.missingMethodArguments, 1)>
		</cfif>

		<!--- Execute Tag --->
    	<cfreturn tag( argumentCollection=arguments.missingMethodArguments )>

    </cffunction>

    <cffunction name="getColumnArray" access="private" returntype="any" output="false" hint="Returns an array of the values">
        <cfargument name="qry"			type="query"	required="true" hint="cf query" />
        <cfargument name="columnName"	type="string"	required="true" hint="column name" />
        <cfscript>
            var arValues = [];

            if( arguments.qry.recordcount ){
                for( var i = 1; i LTE arguments.qry.recordcount; i++){
                    ArrayAppend( arValues, arguments.qry[ arguments.columnName ][ i ] );
                }
            }

            return arValues;
        </cfscript>
    </cffunction>

    <!--- cfhtml head facade --->
	<cffunction name="$htmlhead" access="public" returntype="void" hint="Facade to cfhtmlhead" output="false" >
		<cfargument name="content" required="true" type="string" hint="The content to send to the head">
		<cfhtmlhead text="#arguments.content#">
	</cffunction>

	<!--- ******************** Updated for Equator Requirements ************************************** --->

	<!--- options --->
	<cffunction name="options" access="public" returntype="any" output="false" hint="Render out options. Remember that any extra arguments are passed as tag attributes. Updated from CB 4.0.">
		<cfargument name="values" 			type="any"		required="false" hint="The values array, list, or query to build options for"/>
		<cfargument name="column" 			type="any" 		required="false" default=""	hint="If using a query or array of objects the column to display as value and name"/>
		<cfargument name="nameColumn" 		type="any" 		required="false" default=""	hint="If using a query or array of objects, the name column to display, if not passed defaults to the value column"/>
		<cfargument name="selectedIndex" 	type="any" 		required="false" default="0" hint="selected index(s) if any. So either one or a list of indexes"/>
		<cfargument name="selectedValue" 	type="any" 		required="false" default=""	hint="selected value(s) if any. So either one or a list of values"/>
		<cfargument name="excludedValues"	type="string"	required="false" default=""	hint="A CSV list of option values to exclude from the 'values' source (column)." />
		<cfargument name="emptyOption" 		type="boolean" 	required="false" default="false"	hint="Add an empty (no value) option before the others. If there is only one value, this will be skipped."/>
		<cfargument name="emptyOptionLabel"	type="string" 	required="false" default="Select One"	hint="Label text for the empty option."/>
		<cfargument name="emptyOptionLabelNoData"	type="string" 	required="false" default="{ No options found. }"	hint="Label text for the empty option."/>
		<cfscript>
			var buffer 		= createObject("java","java.lang.StringBuffer").init('');
			var val 		= "";
			var nameVal		= "";
			var x	 		= 1;
			var qColumns 	= "";
			var thisName	= "";
			var thisValue	= "";
			var emptyOptLabel = arguments.emptyOptionLabel;
			var checkExcludedValues = false;
			var includeValue = true;

			if (listLen(arguments.excludedValues) GT 0) {
				checkExcludedValues = true;
			}

			// check if an array? So we can do array of objects check
			if( isArray(arguments.values) AND arrayLen(arguments.values) ){
				// Check first element for an object, if it is then convert to query
				if( isObject(arguments.values[1]) ){
					arguments.values = entityToQuery(arguments.values);
				}
			}
			// is this a simple value, if so, inflate it
			if( isSimpleValue(arguments.values) ){
				arguments.values = listToArray(arguments.values);
			}

			// setup local variables
			val 	= arguments.values;
			nameVal = arguments.values;

			// query normalization?
			if( isQuery(val) ){
				// check if column sent? Else select the first column
				if( NOT len(column) ){
					// select the first one
					qColumns = listToArray( arguments.values.columnList );
					arguments.column = qColumns[1];
				}
				// column for values
				val 	= getColumnArray(arguments.values,arguments.column);
				nameVal = val;
				// name column values
				if( len(arguments.nameColumn) ){
					nameVal = getColumnArray(arguments.values,arguments.nameColumn);
				}
			}

			if (arguments.emptyOption) {	// Should we add an empty option?
				if (arrayLen(val) NEQ 1) {	// If there's only one value, bypass the empty option.
					if (arrayLen(val) EQ 0) {	// If there are no values, set a "no values" message.
						if (len(arguments.emptyOptionLabelNoData) GT 0) {
							emptyOptLabel = arguments.emptyOptionLabelNoData;
						}
					}

					buffer.append('<option value="">');
					if (len(emptyOptLabel) GT 0) {
						buffer.append( encodeForHTML(emptyOptLabel) );
					}
					buffer.append('</option>');
				}
			}

			// values
			for(x=1; x lte arrayLen(val); x++){

				thisValue = val[x];
				thisName = nameVal[x];

				// struct normalizing
				if( isStruct( val[x] ) ){
					// Default
					thisName = thisValue;

					// check for value?
					if( structKeyExists(val[x], "value") ){ thisValue = val[x].value; }
					if( structKeyExists(val[x], "name") ){ thisName = val[x].name; }

					// Check if we have a column to use for the default value
					if( structKeyExists( val[x], arguments.column ) ){ thisValue = val[x][column]; }

					// Do we have name column
					if( len( arguments.nameColumn ) ){
						if( structKeyExists( val[x], arguments.nameColumn ) ){ thisName = val[x][nameColumn]; }
					}
					else{
						if( structKeyExists( val[x], arguments.column ) ){ thisName = val[x][column]; }
					}

				}

				if (checkExcludedValues) {
					includeValue = !listFindNoCase(arguments.excludedValues, thisValue);
				}

				if (includeValue) {
					// create option
					buffer.append('<option value="' & encodeForHTMLAttribute(thisValue) & '"');

					// selected
					if( listfindNoCase( arguments.selectedIndex, x ) ){
						buffer.append('selected="selected"');
					}
					// selected value
					if( listfindNoCase( arguments.selectedValue, thisValue ) ){
						buffer.append('selected="selected"');
					}
					buffer.append(">" & encodeForHTML(thisName) & "</option>");
				}

			}

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="flattenAttributes" output="false" access="private" returntype="any" hint="flatten a struct of attributes to strings. Updated w/ CB 4.0 version.">
		<cfargument name="target" 	type="struct" required="true">
		<cfargument name="excludes" type="any" required="false" default=""/>
		<cfargument name="buffer" 	type="any" required="true"/>
		<cfscript>
			var key	 = "";
			var datakey = "";

			// global exclusions
			arguments.excludes &= ",fieldWrapper,labelWrapper,entity,booleanSelect,textareas,manytoone,onetomany,sendToHeader,bind";

			if (structKeyExists(arguments.target, "class")) {
				if (len(arguments.target.class) GT 0) {
					arguments.target.class &= " cbhtml";
				} else {
					arguments.target.class = "cbhtml";
				}
			} else {
				arguments.target.class = "cbhtml";
			}

			for(key in arguments.target){
				// Excludes
				if( len( arguments.excludes ) AND listFindNoCase( arguments.excludes, key ) ){
					continue;
				}
				// Normal Keys
				if( structKeyExists( arguments.target, key ) AND isSimpleValue( arguments.target[ key ] ) AND len( arguments.target[ key ] ) ){
					arguments.buffer.append(' #lcase( key )#="#encodeForHTMLAttribute(arguments.target[key])#"');
				}
				// data keys
				if( isStruct( arguments.target[ key ] ) ){
					for( dataKey in arguments.target[ key ] ){
						if( isSimplevalue( arguments.target[ key ][ dataKey ] ) AND len( arguments.target[ key ][ dataKey ] ) ){
							arguments.buffer.append(' #lcase( key )#-#lcase( dataKey )#="#encodeForHTMLAttribute(arguments.target[ key ][ datakey ])#"');
						}
					}
				}

			}

			return arguments.buffer;
		</cfscript>
	</cffunction>

	<cffunction name="picker" access="public" returntype="any" output="false" hint="Render out two related select tags, where options can be moved from one to the other.">
		<cfargument name="name"	type="string" required="true" hint="The (unique) name of the picker."/>
		<cfargument name="leftHand" type="struct" required="false" hint="Configuration for left-hand Select (See function 'select')." />
		<cfargument name="rightHand" type="struct" required="false" default="#{}#" hint="Configuration for right-hand Select (See function 'select')." />
		<cfargument name="label" type="string" required="false" hint="Label for the picker."/>
		<cfargument name="labelWrapper" type="string" required="false" default="h3" hint="Tag to wrap about the label."/>
		<cfargument name="size" type="numeric" required="false" default="10" hint="The number of rows in the <select>s that should be visible." />
		<cfargument name="showHelp" type="boolean" required="false" default="true" hint="Show the instructions under the picker." />
		<cfscript>
			var buffer = createObject("java","java.lang.StringBuffer").init('');
			var defaults = {
				pickerID = "pw_" & arguments.name
				, class = "pickerWidget moveOption"
				, selectedClass = "pickerSelectedOptions"
				, multiple = true
				, labelClass = "title"
			};
			/* Left Hand Defaults */
			if (!structKeyExists(arguments.leftHand, "name")) { arguments.leftHand.name = defaults.pickerID & "_lhs"; }
			if (!structKeyExists(arguments.leftHand, "class")) { arguments.leftHand.class = defaults.class; } else { arguments.leftHand.class &= " " & defaults.class; }
			if (!structKeyExists(arguments.leftHand, "size")) { arguments.leftHand.size = arguments.size; }
			if (!structKeyExists(arguments.leftHand, "multiple")) { arguments.leftHand.multiple = defaults.multiple; }
			if (!structKeyExists(arguments.leftHand, "label")) { arguments.leftHand.label = "Available"; }
			if (!structKeyExists(arguments.leftHand, "labelClass")) { arguments.leftHand.labelClass = defaults.labelClass; }
			/* Right Hand Defaults */
			if (!structKeyExists(arguments.rightHand, "name")) { arguments.rightHand.name = arguments.name; }
			if (!structKeyExists(arguments.rightHand, "id")) { arguments.rightHand.id = defaults.pickerID & "_rhs"; }
			if (!structKeyExists(arguments.rightHand, "class")) { arguments.rightHand.class = defaults.class & " " & defaults.selectedClass ; } else { arguments.rightHand.class &= " " & defaults.class & " " & defaults.selectedClass; }
			if (!structKeyExists(arguments.rightHand, "size")) { arguments.rightHand.size = arguments.size; }
			if (!structKeyExists(arguments.rightHand, "multiple")) { arguments.rightHand.multiple = defaults.multiple; }
			if (!structKeyExists(arguments.rightHand, "label")) { arguments.rightHand.label = "Selected"; }
			if (!structKeyExists(arguments.rightHand, "labelClass")) { arguments.rightHand.labelClass = defaults.labelClass; }
			// Finish prepping arguments.
			normalizeID(arguments.leftHand);
			normalizeID(arguments.rightHand);
			// Data Defaults
			if (!structKeyExists(arguments.leftHand, "data")) { arguments.leftHand.data = {}; }
			if (!structKeyExists(arguments.leftHand.data, "target")) { arguments.leftHand.data.target = arguments.rightHand.id; }
			if (!structKeyExists(arguments.rightHand, "data")) { arguments.rightHand.data = {}; }
			if (!structKeyExists(arguments.rightHand.data, "target")) { arguments.rightHand.data.target = arguments.leftHand.id; }


			/* Building the Picker */
			buffer.append('<div class="' & defaults.class & '">');
			if (structKeyExists(arguments, "label")) {
				buffer.append( tag ( arguments.labelWrapper, arguments.label ) );
			}
			buffer.append('<table id="pw_' & arguments.name & '">');
			buffer.append('<tr><td>');
			buffer.append( select( argumentCollection = arguments.leftHand ) );
			buffer.append('</td><td class="pickerButtons">');
			buffer.append( button( name = defaults.pickerID & "moveOneRight", value = "  >  ", wrapper = "p", label = " ", class = "moveOption", data = { source = arguments.lefthand.id, target = arguments.righthand.id }) );
			buffer.append( button( name = defaults.pickerID & "moveOneLeft", value = "  <  ", wrapper = "p", class = "moveOption", data = { source = arguments.righthand.id, target = arguments.lefthand.id }) );
			buffer.append( button( name = defaults.pickerID & "moveAllRight", value = " >> ", wrapper = "p", class = "moveOption", data = { source = arguments.lefthand.id, target = arguments.righthand.id, moveall = true }) );
			buffer.append( button( name = defaults.pickerID & "moveAllLeft", value = " << ", wrapper = "p", class = "moveOption", data = { source = arguments.righthand.id, target = arguments.lefthand.id, moveall = true }) );

			buffer.append('</td><td>');
			buffer.append( select( argumentCollection = arguments.rightHand ) );
			buffer.append('</td></tr>');
			if (arguments.showHelp) {
				buffer.append('<tr><td colspan="3"><p class="centerAlign">Double click on any entry to move it between lists.</p></td></tr>');
			}
			buffer.append('</table></div>');

			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="wsSectionLinks" access="public" returntype="string" output="false" hint="I create a line of link buttons with an optional header.">
		<cfargument name="hrefConfig" type="array" required="true" hint="An array of structs, defining the links to generate via html.href()." />
		<cfargument name="name"	type="string" required="false" hint="The id/name of this Section."/>
		<cfargument name="headerLabel" type="string" required="false" hint="The content of the header."/>
		<cfargument name="headerLevel" type="numeric" required="false" default="3" hint="The numeric value of H1, H2, etc."/>
		<cfscript>
			var buffer = createObject("java","java.lang.StringBuffer").init('');
			var x = 0;
			var y = arrayLen(arguments.hrefConfig);

			buffer.append('<div');
			if (structKeyExists(arguments, "name")) {
				buffer.append(' id="' & encodeForHTMLAttribute(arguments.name) & '"');
			}
			buffer.append(' class="linkButtonRow clearfix wsStackableSection">');
			if (structKeyExists(arguments, "headerLabel")) {
				buffer.append('<h' & arguments.headerLevel & ' class="left linkButtonHeader">' & arguments.headerLabel & '</h' & arguments.headerLevel & '>');
			}
			for ( x = 1; x lte y; x++ ) {
				if (structKeyExists(arguments.hrefConfig[x], "allowByPrivilege")) {
					if (arguments.hrefConfig[x].allowByPrivilege) {
						buffer.append( wsLinkButton( config = arguments.hrefConfig[x], position = x, total = y ) );
					}
				} else {
					buffer.append( wsLinkButton( config = arguments.hrefConfig[x], position = x, total = y ) );
				}

			}
			buffer.append('</div>');
			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="wsLinkButton" access="public" returntype="string" output="false" hint="I create a link, styled like a button.">
		<cfargument name="config" type="struct" required="true" hint="The arguments defined by html.href()"/>
		<cfargument name="position" type="numeric" required="false" default="-1" />
		<cfargument name="total" type="numeric" required="false" default="0" />
		<cfparam name="arguments.config.class" default="" />

		<cfscript>
		var buffer = createObject("java","java.lang.StringBuffer").init('');
		var defaultClass = "";
		if (arguments.position EQ 1) {
			defaultClass = "first";


		}
		if ((arguments.position GT 1) AND (arguments.position EQ arguments.total)) {
			defaultClass = "last";
		}
		if (len(arguments.config.class) eq 0){
			arguments.config.class = defaultClass;
		} else {
			arguments.config.class = config.class & " " & defaultClass;
		}
		buffer.append('<div class="linkButton">');
		buffer.append(href(argumentCollection = arguments.config));
		buffer.append('</div>');
		return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="wsRoundedSection" output="false" access="public" returntype="any" hint="Surround content with a tag">
		<cfargument name="content" type="string" required="false" default="" hint="Should be the results of event.renderView()."/>
		<cfscript>
			var buffer = createObject("java","java.lang.StringBuffer").init("");
			buffer.append( wsRoundedSectionStart() );
			buffer.append( arguments.content );
			buffer.append( wsRoundedSectionEnd() );
			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="wsRoundedSectionStart" output="false" access="public" returntype="any" hint="Surround content with a tag">
		<cfargument name="content" type="string" required="false" default="" hint="Should be the results of event.renderView()."/>
		<cfscript>
			var buffer	= createObject("java","java.lang.StringBuffer").init("");
			buffer.append('<div class="roundedContentContainer"><b class="roundTop"><b class="cornerPart1"></b><b class="cornerPart2"></b><b class="cornerPart3"></b><b class="cornerPart4"></b></b><div class="roundedContent">');
			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="wsRoundedSectionEnd" output="false" access="public" returntype="any" hint="Surround content with a tag">
		<cfargument name="content" type="string" required="false" default="" hint="Should be the results of event.renderView()."/>
		<cfscript>
			var buffer	= createObject("java","java.lang.StringBuffer").init("");
			buffer.append('</div><b class="roundBottom"><b class="cornerPart4"></b><b class="cornerPart3"></b><b class="cornerPart2"></b><b class="cornerPart1"></b></b></div>');
			return buffer.toString();
		</cfscript>
	</cffunction>

	<cffunction name="selectState" access="public" returntype="any" output="false" hint="Render out a select tag populated with US state options. Uses the same arguments as the basic <select> function.">
		<cfargument name="name" 			type="string" 	required="false" default="" hint="The name of the field"/>
		<cfargument name="verbose"			type="boolean" required="false" default="true" hint="Show the long name of a state (default) or the two character abbreviation."/>
		<cfargument name="allOption" 		type="boolean" 	required="false" default="false" hint="Add an empty (no value) option before the others. If there is only one value, this will be skipped."/>
		<cfargument name="selectedValue" 	type="string" 	required="false" default="" hint="selected value if any"/>
		<cfargument name="excludedValues" 	type="string" 	required="false" default="" hint="A CSV list of option values to exclude from the 'values' column." />
		<cfscript>
			var config = {
				values = stateOptions()
				, column = "key"
				, nameColumn = "label"
				, selectedValue = arguments.selectedValue
				, emptyOption = arguments.allOption
				, emptyOptionLabel = "All"
				, excludedValues = arguments.excludedValues
			};

			if (!structKeyExists(arguments, "options")) {
				if (!arguments.verbose) {
					config.nameColumn = "key";
				}
				arguments.options = options(argumentCollection = config);
			}
			return select(argumentCollection = arguments);
		</cfscript>
	</cffunction>

	<cffunction name="stateOptions" output="false" access="public" returntype="array" hint="Standard list of US states and territories.">
		<cfargument name="limitOptions" type="string" required="false" hint="CSV list of States to return." />
		<cfset var aLimitStates = [] />
		<cfset var aStates = [
			{key = "AL", label = "Alabama"}
			, {key = "AK", label = "Alaska"}
			, {key = "AS", label = "American Samoa"}
			, {key = "AZ", label = "Arizona"}
			, {key = "AR", label = "Arkansas"}
			, {key = "CA", label = "California"}
			, {key = "CO", label = "Colorado"}
			, {key = "CT", label = "Connecticut"}
			, {key = "DE", label = "Delaware"}
			, {key = "DC", label = "District of Columbia"}
			, {key = "FM", label = "Fed.Sts. of Micronesia"}
			, {key = "FL", label = "Florida"}
			, {key = "GA", label = "Georgia"}
			, {key = "GU", label = "Guam"}
			, {key = "HI", label = "Hawaii"}
			, {key = "ID", label = "Idaho"}
			, {key = "IL", label = "Illinois"}
			, {key = "IN", label = "Indiana"}
			, {key = "IA", label = "Iowa"}
			, {key = "KS", label = "Kansas"}
			, {key = "KY", label = "Kentucky"}
			, {key = "LA", label = "Louisiana"}
			, {key = "ME", label = "Maine"}
			, {key = "MH", label = "Marshall Islands"}
			, {key = "MD", label = "Maryland"}
			, {key = "MA", label = "Massachusetts"}
			, {key = "MI", label = "Michigan"}
			, {key = "MN", label = "Minnesota"}
			, {key = "MS", label = "Mississippi"}
			, {key = "MO", label = "Missouri"}
			, {key = "MT", label = "Montana"}
			, {key = "NE", label = "Nebraska"}
			, {key = "NV", label = "Nevada"}
			, {key = "NH", label = "New Hampshire"}
			, {key = "NJ", label = "New Jersey"}
			, {key = "NM", label = "New Mexico"}
			, {key = "NY", label = "New York"}
			, {key = "NC", label = "North Carolina"}
			, {key = "ND", label = "North Dakota"}
			, {key = "MP", label = "N. Mariana Islands"}
			, {key = "OH", label = "Ohio"}
			, {key = "OK", label = "Oklahoma"}
			, {key = "OR", label = "Oregon"}
			, {key = "PW", label = "Palau"}
			, {key = "PA", label = "Pennsylvania"}
			, {key = "PR", label = "Puerto Rico"}
			, {key = "RI", label = "Rhode Island"}
			, {key = "SC", label = "South Carolina"}
			, {key = "SD", label = "South Dakota"}
			, {key = "TN", label = "Tennessee"}
			, {key = "TX", label = "Texas"}
			, {key = "UT", label = "Utah"}
			, {key = "VT", label = "Vermont"}
			, {key = "VA", label = "Virginia"}
			, {key = "VI", label = "Virgin Islands"}
			, {key = "WA", label = "Washington"}
			, {key = "WV", label = "West Virginia"}
			, {key = "WI", label = "Wisconsin"}
			, {key = "WY", label = "Wyoming"}
		] />
		<cfif structKeyExists(arguments, "limitOptions")>
			<cfloop list="#arguments.limitOptions#" index="local.x">
				<cfloop array="#aStates#" index="local.state">
					<cfif local.state.key EQ local.x>
						<cfset arrayAppend(aLimitStates, local.state) />
						<cfbreak />
					</cfif>
				</cfloop>
			</cfloop>
		</cfif>

		<cfif arrayLen(aLimitStates) GT 0>
			<cfreturn aLimitStates />
		<cfelse>
			<cfreturn aStates />
		</cfif>

	</cffunction>

</cfcomponent>
