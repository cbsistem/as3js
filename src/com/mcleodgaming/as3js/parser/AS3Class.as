package com.mcleodgaming.as3js.parser
{
	import com.mcleodgaming.as3js.AS3JS;
	import com.mcleodgaming.as3js.enums.*;
	import com.mcleodgaming.as3js.types.*;
	import com.mcleodgaming.as3js.util.*;
	
	public class AS3Class 
	{
		public static var reservedWords:Array = ["as", "class", "delete", "false", "if", "instanceof", "native", "private", "super", "to", "use", "with", "break", "const", "do", "finally", "implements", "new", "protected", "switch", "true", "var", "case", "continue", "else", "for", "import", "internal", "null", "public", "this", "try", "void", "catch", "default", "extends", "function", "in", "is", "package", "return", "throw", "typeof", "while", "each", "get", "set", "namespace", "include", "dynamic", "final", "natiev", "override", "static", "abstract", "char", "export", "long", "throws", "virtual", "boolean", "debugger", "float", "prototype", "to", "volatile", "byte", "double", "goto", "short", "transient", "cast", "enum", "intrinsic", "synchronized", "type"];
		
		public static var nativeTypes:Array = ["Boolean", "Number", "int", "uint", "String" ];
		
		public var packageName:String;
		public var className:String;
		public var imports:Vector.<String>;
		public var requires:Vector.<String>;
		public var importWildcards:Vector.<String>;
		public var importExtras:Vector.<String>;
		public var interfaces:Vector.<String>;
		public var parent:String;
		public var parentDefinition:AS3Class;
		public var members:Vector.<AS3Member>;
		public var staticMembers:Vector.<AS3Member>;
		public var getters:Vector.<AS3Member>;
		public var setters:Vector.<AS3Member>;
		public var staticGetters:Vector.<AS3Member>;
		public var staticSetters:Vector.<AS3Member>;
		public var isInterface:Boolean;
		public var fieldMap:Object;
		public var staticFieldMap:Object;
		public var importMap:Object;
			
		public function AS3Class() 
		{
			packageName = null;
			className = null;
			imports = new Vector.<String>();
			requires = new Vector.<String>();
			importWildcards = new Vector.<String>();
			importExtras = new Vector.<String>();
			interfaces = new Vector.<String>();
			parent = null;
			parentDefinition = null;
			members = new Vector.<AS3Member>();
			staticMembers = new Vector.<AS3Member>();
			getters = new Vector.<AS3Member>();
			setters = new Vector.<AS3Member>();
			staticGetters = new Vector.<AS3Member>();
			staticSetters = new Vector.<AS3Member>();
			isInterface = false;
			fieldMap = {};
			staticFieldMap = {};
			importMap = {};
		}
		
		public function registerImports(clsList:Vector.<AS3Class>):void
		{
			var i;
			for (i in imports)
			{
				if (clsList[imports[i]])
				{
					var lastIndex:int = imports[i].lastIndexOf(".");
					var shorthand:String = (lastIndex < 0) ? imports[i] : imports[i].substr(lastIndex + 1);
					importMap[shorthand] = clsList[imports[i]];
				}
			}
			for (i in importExtras)
			{
				if (clsList[importExtras[i]])
				{
					var lastIndex:int = importExtras[i].lastIndexOf(".");
					var shorthand:String = (lastIndex < 0) ? importExtras[i] : importExtras[i].substr(lastIndex + 1);
					importMap[shorthand] = clsList[importExtras[i]];
				}
			}
		}
		public function registerField(name:String, value:AS3Member):void
		{
			if (value && value.isStatic)
			{
				staticFieldMap[name] = staticFieldMap[name] || value;
			} else
			{
				fieldMap[name] = fieldMap[name] || value;
			}
		}
		public function retrieveField(name:String, isStatic:Boolean):AS3Member
		{
			if (isStatic)
			{
				if (staticFieldMap[name])
				{
					return staticFieldMap[name];
				} else if (parentDefinition)
				{
					return parentDefinition.retrieveField(name, isStatic);
				} else
				{
					return null;
				}
			} else
			{
				if (fieldMap[name])
				{
					return fieldMap[name];
				} else if (parentDefinition)
				{
					return parentDefinition.retrieveField(name, isStatic);
				} else
				{
					return null;
				}
			}
		}
		public function needsImport(pkg:String):Boolean
		{
			var i:*;
			var j:*;
			var lastIndex:int = pkg.lastIndexOf(".");
			var shorthand:String = (lastIndex < 0) ? pkg : pkg.substr(lastIndex + 1);
			var matches:Vector.<AS3Member>;

			if (imports.indexOf(pkg) >= 0)
			{
				return false; //Class was already imported
			}

			if (shorthand == className && pkg == packageName)
			{
				return true; //Don't need self
			}
				
			if (shorthand == parent)
			{
				return true; //Parent class is in another package
			}
			
			//Now we must parse through all members one by one, looking at functions and variable types to determine the necessary imports
				
			for (i in members)
			{
				//See if the function definition or variable assigment have a need for this package
				if (members[i] instanceof AS3Function)
				{
					matches = members[i].value.match(AS3Pattern.VARIABLE_DECLARATION[1]);
					for (j in matches)
					{
						if(matches[j].split(":")[1] == shorthand)
							return true;
					}
					for (j in members[i].argList)
					{
						if(typeof members[i].argList[j].type == 'string' && members[i].argList[j].type == shorthand)
							return true;
					}
				}
				if (typeof members[i].value == 'string' && members[i].value.match(new RegExp("([^a-zA-Z_$.])" + shorthand + "([^0-9a-zA-Z_$])", "g")))
				{
					return true;
				} else if (typeof members[i].type == 'string' && members[i].type == shorthand)
				{
					return true;
				}
			}
			for (i in staticMembers)
			{
				//See if the function definition or variable assigment have a need for this package
				if (staticMembers[i] instanceof AS3Function)
				{
					matches = staticMembers[i].value.match(AS3Pattern.VARIABLE_DECLARATION[1]);
					for (j in matches)
					{
						if (matches[j].split(":")[1] == shorthand)
						{
							return true;
						}
					}
					for (j in staticMembers[i].argList) 
					{
						if (typeof staticMembers[i].argList[j].type == 'string' && staticMembers[i].argList[j].type == shorthand)
						{
							return true;
						}
					}
				}
				if (typeof staticMembers[i].value == 'string' && staticMembers[i].value.match(new RegExp("([^a-zA-Z_$.])" + shorthand + "([^0-9a-zA-Z_$])", "g")))
				{
					return true;
				} else if (typeof staticMembers[i].type == 'string' && staticMembers[i].type == shorthand)
				{
					return true;
				}
			}
			for (i in getters)
			{
				//See if the function definition or variable assigment have a need for this package
				matches = getters[i].value.match(AS3Pattern.VARIABLE_DECLARATION[1]);
				for (j in matches)
				{
					if (matches[j].split(":")[1] == shorthand)
					{
						return true;
					}
				}
				for (j in getters[i].argList)
				{
					if (typeof getters[i].argList[j].type == 'string' && getters[i].argList[j].type == shorthand)
					{
						return true;
					}
				}
				if (typeof getters[i].value == 'string' && getters[i].value.match(new RegExp("([^a-zA-Z_$.])" + shorthand + "([^0-9a-zA-Z_$])", "g")))
				{
					return true;
				} else if (typeof getters[i].type == 'string' && getters[i].type == shorthand)
				{
					return true;
				}
			}
			for (i in setters)
			{
				matches = setters[i].value.match(AS3Pattern.VARIABLE_DECLARATION[1]);
				for (j in matches)
				{
					if (matches[j].split(":")[1] == shorthand)
					{
						return true;
					}
				}
				//See if the function definition or variable assigment have a need for this package
				for (j in setters[i].argList) 
				{
					if (typeof setters[i].argList[j].type == 'string' && setters[i].argList[j].type == shorthand)
					{
						return true;
					}
				}
				if (typeof setters[i].value == 'string' && setters[i].value.match(new RegExp("([^a-zA-Z_$.])" + shorthand + "([^0-9a-zA-Z_$])", "g")))
				{
					return true;
				} else if (typeof setters[i].type == 'string' && setters[i].type == shorthand)
				{
					return true;
				}
			}
			for (i in staticGetters)
			{
				matches = staticGetters[i].value.match(AS3Pattern.VARIABLE_DECLARATION[1]);
				for (j in matches)
				{
					if (matches[j].split(":")[1] == shorthand)
					{
						return true;
					}
				}
				//See if the function definition or variable assigment have a need for this package
				for (j in staticGetters[i].argList)
				{
					if (typeof staticGetters[i].argList[j].type == 'string' && staticGetters[i].argList[j].type == shorthand)
					{
						return true;
					}
				}
				if (typeof staticGetters[i].value == 'string' && staticGetters[i].value.match(new RegExp("([^a-zA-Z_$.])" + shorthand + "([^0-9a-zA-Z_$])", "g")))
				{
					return true;
				} else if (typeof staticGetters[i].type == 'string' && staticGetters[i].type == shorthand)
				{
					return true;
				}
			}
			for (i in staticSetters)
			{
				matches = staticSetters[i].value.match(AS3Pattern.VARIABLE_DECLARATION[1]);
				for (j in matches)
				{
					if (matches[j].split(":")[1] == shorthand)
					{
						return true;
					}
				}
				for (j in staticSetters[i].argList)
				{
					if (typeof staticSetters[i].argList[j].type == 'string' && staticSetters[i].argList[j].type == shorthand)
					{
						return true;
					}
				}
				//See if the function definition or variable assigment have a need for this package
				if (typeof staticSetters[i].value == 'string' && staticSetters[i].value.match(new RegExp("([^a-zA-Z_$.])" + shorthand + "([^0-9a-zA-Z_$])", "g")))
				{
					return true;
				} else if (typeof staticSetters[i].type == 'string' && staticSetters[i].type == shorthand)
				{
					return true;
				}
			}
			
			return false;
		}
		public function addImport(pkg:String):void
		{
			if (imports.indexOf(pkg) < 0)
			{
				imports.push(pkg);
			}
		}
		public function addExtraImport(pkg:String):void
		{
			if (importExtras.indexOf(pkg) < 0)
			{
				importExtras.push(pkg);
			}
		}
		public function findParents(classes:Vector.<AS3Class>):void
		{
			if (!parent)
			{
				return;
			}
			for (var i in classes)
			{
				//Only gather vars from the parent
				if (classes[i] != this && parent == classes[i].className)
				{
					parentDefinition = classes[i]; //Found our parent
					return;
				}
			}
		}
		public function stringifyFunc(fn:AS3Member):String
		{
			var buffer:String = "";
			if (fn instanceof AS3Function)
			{
				//Functions need to be handled differently
				buffer += "\t\t";
				//Prepend sub-type if it exists
				if (fn.subType)
				{
					buffer += fn.subType + '_';
				}
				//Print out the rest of the name and start the function definition
				buffer += (fn.name == className) ? "_constructor_" : fn.name
				buffer += ": function(";
				//Concat all of the arguments together
				tmpArr = [];
				for (j = 0; j < fn.argList.length; j++)
				{
					if (!fn.argList[j].isRestParam)
					{
						tmpArr.push(fn.argList[j].name);
					}
				}
				buffer += tmpArr.join(", ") + ") ";
				//Function definition is finally added
				buffer += fn.value + ",\n";
			} else if (fn instanceof AS3Variable)
			{
				buffer += "\t\t";
				//Variables can be added immediately
				buffer += fn.name;
				buffer += ": " + fn.value + ",\n";
			}
			return buffer;
		}
		
		public function process(classes:Vector.<AS3Class>):void
		{
			var self:AS3Class = this;
			var i:int;
			var index:int;
			var currParent:AS3Class = this;
			var allMembers:Vector.<AS3Member> = new Vector.<AS3Member>();
			var allFuncs:Vector.<AS3Function> = new Vector.<AS3Function>();
			var allStaticMembers:Vector.<AS3Member> = new Vector.<AS3Member>();
			var allStaticFuncs:Vector.<AS3Function> = new Vector.<AS3Function>();

			while (currParent)
			{
				//Parse members of this parent
				for (i in currParent.setters)
				{
					allMembers.push(currParent.setters[i]);
				}
				for (i in currParent.staticSetters)
				{
					allStaticMembers.push(currParent.staticSetters[i]);
				}
				for (i in currParent.getters)
				{
					allMembers.push(currParent.getters[i]);
				}
				for (i in currParent.staticGetters)
				{
					allStaticMembers.push(currParent.staticGetters[i]);
				}
				for (i in currParent.members)
				{
					allMembers.push(currParent.members[i]);
				}
				for (i in currParent.staticMembers)
				{
					allStaticMembers.push(currParent.staticMembers[i]);
				}
					
				//Go to the next parent
				currParent = currParent.parentDefinition;
			}
			
			//Add copies of the setters and getters to the "all" arrays (for convenience)
			for (i in setters)
			{
				if (setters[i] instanceof AS3Function)
				{
					allFuncs.push(setters[i]);
				}
			}
			for (i in staticSetters)
			{
				if (staticSetters[i] instanceof AS3Function)
				{
					allStaticFuncs.push(staticSetters[i]);
				}
			}
			for (i in getters)
			{
				if (getters[i] instanceof AS3Function)
				{
					allFuncs.push(getters[i]);
				}
			}
			for (i in staticGetters)
			{
				if (staticGetters[i] instanceof AS3Function)
				{
					allStaticFuncs.push(staticGetters[i]);
				}
			}
			for (i in members)
			{
				if (members[i] instanceof AS3Function)
				{
					allFuncs.push(members[i]);
				}
			}
			for (i in staticMembers)
			{
				if (staticMembers[i] instanceof AS3Function)
				{
					allStaticFuncs.push(staticMembers[i]);
				}
			}

			
			for (i in allFuncs)
			{
				AS3JS.debug("Now parsing function: " + className + ":" + allFuncs[i].name);
				allFuncs[i].value = AS3Parser.parseFunc(this, allFuncs[i].value, allFuncs[i].buildLocalVariableStack(), allFuncs[i].isStatic)[0];
				allFuncs[i].value = AS3Parser.checkArguments(allFuncs[i]);
				if (allFuncs[i].name === className)
				{
					//Inject instantiations here
					allFuncs[i].value = AS3Parser.injectInstantiations(this, allFuncs[i]);
				}
				allFuncs[i].value = AS3Parser.cleanup(allFuncs[i].value);
				//Fix supers
				allFuncs[i].value = allFuncs[i].value.replace(/super\.(.*?)\(/g, parent + '.prototype.$1.call(this, ').replace(/\.call\(this,\s*\)/g, ".call(this)");
				allFuncs[i].value = allFuncs[i].value.replace(/super\(/g, parent + '.prototype._constructor_.call(this, ').replace(/\.call\(this,\s*\)/g, ".call(this)");
				allFuncs[i].value = allFuncs[i].value.replace(new RegExp("this[.]" + parent, "g"), parent); //Fix extra 'this' on the parent
			}
			for (i in allStaticFuncs)
			{
				AS3JS.debug("Now parsing static function: " + className + ":" + allStaticFuncs[i].name);
				allStaticFuncs[i].value = AS3Parser.parseFunc(this, allStaticFuncs[i].value, allStaticFuncs[i].buildLocalVariableStack(), allStaticFuncs[i].isStatic)[0];
				allStaticFuncs[i].value = AS3Parser.checkArguments(allStaticFuncs[i]);
				allStaticFuncs[i].value = AS3Parser.cleanup(allStaticFuncs[i].value);
			}
		}
		public function toString():String
		{
			//Outputs the class in JS format
			var i:*;
			var j:*;
			var buffer:String = "ImportJS.pack('" + packageName + '.' + className + "', function(module, exports) {\n";
			
			if (requires.length > 0)
			{
				for (var i in requires)
				{
					buffer += '\tvar ' + requires[i].substring(1, requires[i].length-1) + ' = require(' + requires[i] + ');\n';
				}
				buffer += "\n";
			}
		
			var tmpArr:Array = null;

			//Parent class must be imported if it exists
			if (parentDefinition)
			{
				buffer += "\tvar " + parentDefinition.className + " = this.import('" + parentDefinition.packageName + "." + parentDefinition.className + "');\n";
			}

			//Create refs for all the other classes
			if (imports.length > 0)
			{
				tmpArr = [];
				for (i in imports)
				{
					if (imports[i].indexOf('flash.') < 0 && parent != imports[i].substr(imports[i].lastIndexOf('.') + 1) && packageName + '.' + className != imports[i]) //Ignore flash imports
					{
						tmpArr.push(imports[i].substr(imports[i].lastIndexOf('.') + 1)); //<-This will return characters after the final '.', or the entire tring
					}
				}
				//Join up separated by commas
				if (tmpArr.length > 0)
				{
					buffer += '\tvar ';
					buffer += tmpArr.join(", ") + ";\n";
				}
			}
			//Check for injection function code
			var injectedText = "";
			for (i in imports)
			{
				if (imports[i].indexOf('flash.') < 0 && packageName + '.' + className != imports[i]) //Ignore flash imports
				{
					injectedText += "\t\t" + imports[i].substr(imports[i].lastIndexOf('.') + 1) + " = this.import('" + imports[i] + "');\n";
				}
			}
			//Set the non-native statics vars now
			for (i in staticMembers)
			{
				if (!(staticMembers[i] instanceof AS3Function))
				{
					injectedText += AS3Parser.cleanup('\t\t' + className + '.' + staticMembers[i].name + ' = ' + staticMembers[i].value + ";\n");
				}
			}
			
			if (injectedText.length > 0)
			{
				buffer += "\tthis.inject(function () {\n";
				buffer += injectedText;
				buffer += "\t});\n";
			}

			buffer += '\n';
			
			buffer += "\tvar " + className + " = ";
			buffer += (parent) ? parent : "OOPS";
			buffer += ".extend({\n";

			if (staticMembers.length > 0)
			{
				//Place the static members first (skip the ones that aren't native types, we will import later
				buffer += "\t\t_statics_: {\n\t";
				for (i in staticMembers)
				{
					if (staticMembers[i] instanceof AS3Function)
					{
						buffer += AS3Parser.increaseIndent(stringifyFunc(staticMembers[i]), 1, 0);
					} else if (staticMembers[i].type === "Number" || staticMembers[i].type === "int" || staticMembers[i].type === "uint")
					{
						if (isNaN(parseInt(staticMembers[i].value)))
						{
							buffer += AS3Parser.increaseIndent('\t\t' + staticMembers[i].name + ': 0,\n', 1, 0);
						} else
						{
							buffer += AS3Parser.increaseIndent(stringifyFunc(staticMembers[i]), 1, 0);
						}
					} else if (staticMembers[i].type === "Boolean")
					{
						buffer += AS3Parser.increaseIndent('\t\t' + staticMembers[i].name + ': false,\n', 1, 0);
					} else
					{
						buffer += AS3Parser.increaseIndent('\t\t' + staticMembers[i].name + ': null,\n', 1, 0);
					}
				}
				for (i in staticGetters)
				{
					buffer += AS3Parser.increaseIndent(stringifyFunc(staticGetters[i]), 1, 0);
				}
				for (i in staticSetters)
				{
					buffer += AS3Parser.increaseIndent(stringifyFunc(staticSetters[i]), 1, 0);
				}
				buffer = buffer.substr(0, buffer.lastIndexOf(',')) + '\n\t';
				buffer += "\t},\n";
			}		
			for (i in getters)
			{
				buffer += stringifyFunc(getters[i]);
			}
			for (i in setters)
			{
				buffer += stringifyFunc(setters[i]);
			}
			for (i in members)
			{
				if (members[i] instanceof AS3Function || (AS3Class.nativeTypes.indexOf(members[i].type) >= 0 && members[i].value))
				{
					buffer += stringifyFunc(members[i]); //Print functions immediately
				} else if (members[i].type === "Number" || members[i].type === "int" || members[i].type === "uint")
				{
					if (isNaN(parseInt(members[i].value)))
					{
						buffer += AS3Parser.increaseIndent('\t\t' + members[i].name + ': 0,\n', 1, 0);
					} else
					{
						buffer += stringifyFunc(members[i]);
					}
				} else if (members[i].type === "Boolean")
				{
					buffer += AS3Parser.increaseIndent('\t\t' + members[i].name + ': false,\n', 1, 0);
				} else
				{
					buffer += AS3Parser.increaseIndent('\t\t' + members[i].name + ': null,\n', 1, 0);
				}
			}

			buffer = buffer.substr(0, buffer.length - 2) + "\n"; //Strips the final comma out of the string

			buffer += "\t});\n"
			buffer += "\n";
			buffer += "\tmodule.exports = " + className + ";\n";
			buffer += "});";

			//Remaining fixes
			buffer = buffer.replace(/(this\.)+/g, "this.");

			return buffer;
		}
	}
}