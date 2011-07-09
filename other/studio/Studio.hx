import format.hxsl.Data.Tools;

enum VarType {
	VTVector;
	VTMatrix;
	VTTexture;
}

enum VarValue {
	VVector( v : flash.geom.Vector3D, size : Int );
	VMatrix( m : Matrix, width : Int, height : Int, transpose : Bool );
	VTexture( t : flash.display3D.textures.Texture );
}

class Studio {
	
	var mc : flash.display.MovieClip;
	var cnx : haxe.remoting.Connection;
	var stage : flash.display.Stage3D;
	var c : flash.display3D.Context3D;
	var pol : Polygon;
	var camera : Camera;
	var shader : flash.display3D.Program3D;
	var shaderInfos : format.hxsl.Data;
	var vars : Hash<{ v : VarValue, t : VarType }>;
	var time : Float;
	var tex : flash.display3D.textures.Texture;
		
	function new(mc) {
		this.mc = mc;
		time = 0.;
		vars = new Hash();
		var ctx = new haxe.remoting.Context();
		ctx.addObject("api", this);
		cnx = haxe.remoting.ExternalConnection.jsConnect("cnx", ctx).api;
		
		mc.addEventListener(flash.events.Event.ENTER_FRAME, update);
		
		stage = mc.stage.stage3Ds[0];
		stage.viewPort = new flash.geom.Rectangle(0,0,mc.stage.stageWidth,mc.stage.stageHeight);
		stage.addEventListener(flash.events.Event.CONTEXT3D_CREATE, onReady);
		stage.requestContext3D();
	}
		
	function onReady(_) {
		c = stage.context3D;
		c.enableErrorChecking = true;
		var w = Std.int(stage.viewPort.width);
		var h = Std.int(stage.viewPort.height);
		c.configureBackBuffer( w, h, 0, true );
		
		camera = new Camera();
		camera.pos.set(1, 1.5, 2);
		camera.ratio = 1;

		var size = 256;
		tex = c.createTexture(size, size, flash.display3D.Context3DTextureFormat.BGRA, false);
		var bmp = new flash.display.BitmapData(size, size, true, 0);
		bmp.perlinNoise(128, 128, 3, 0, true, true, 7);
		tex.uploadFromBitmapData(bmp);
		bmp.dispose();
		
		initVars();

		pol = new Cube();
		pol.unindex();
		pol.addTCoords();
		pol.addNormals();
		pol.alloc(c);
		
		var code = DEFAULT_HXSL;
		cnx.onFlashInit.call([code]);
	}
	
	function buildConstants( code : format.hxsl.Data.Code ) {
		var tbl = new flash.Vector<Float>();
		for( c in code.consts ) {
			for( f in c )
				tbl.push(Std.parseFloat(f));
			for( i in c.length...4 )
				tbl.push(0.);
		}
		var tindex = 0;
		for( a in code.args.concat(code.tex) ) {
			var v = vars.get(a.name);
			switch( v.v ) {
			case VVector(v,size):
				tbl.push(v.x);
				tbl.push(size > 1 ? v.y : 0.);
				tbl.push(size > 2 ? v.z : 0.);
				tbl.push(size > 3 ? v.w : 0.);
			case VMatrix(m, w, h, tr):
				var raw = m.toMatrix().rawData;
				for( y in 0...w )
					for( x in 0...h ) {
						var index = if( tr ) y + x * 4 else x + y * 4;
						tbl.push(raw[index]);
					}
			case VTexture(t):
				c.setTextureAt(tindex++, t);
			}
		}
		return tbl;
	}
	
	function initVars() {
		camera.update();
		time += 0.01;
		var mproj = camera.m;
		var mpos = new Matrix();
		mpos.initRotateZ(time);
		mpos.translate( -0.5, -0.5, -0.5);

		// copy variables
		vars.set("mpos", { v : VMatrix(mpos, 4, 4, true), t : VTMatrix } );
		vars.set("mproj", { v : VMatrix(mproj, 4, 4, true), t : VTMatrix } );
		vars.set("time", { v : VVector(new flash.geom.Vector3D(time), 1), t : VTVector } );
		vars.set("tex", { v : VTexture(tex), t : VTTexture } );
	}

	function update(_) {
		if( c == null || shader == null ) return;


		c.clear(0, 0, 0, 1);
		c.setDepthTest( true, flash.display3D.Context3DCompareMode.LESS_EQUAL );
		c.setCulling(flash.display3D.Context3DTriangleFace.BACK);

		initVars();
		
		// init shader
		c.setProgram(shader);
		c.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.VERTEX, 0, buildConstants(shaderInfos.vertex));
		c.setProgramConstantsFromVector(flash.display3D.Context3DProgramType.FRAGMENT, 0, buildConstants(shaderInfos.fragment));
		
		// bind
		var VB = flash.display3D.Context3DVertexBufferFormat;
		var vformats = [null,VB.FLOAT_1,VB.FLOAT_2,VB.FLOAT_3,VB.FLOAT_4];
		for( i in 0...shaderInfos.input.length ) {
			var inp = shaderInfos.input[i];
			var index = Lambda.indexOf(INPUTS,inp.name);
			var offset = 0;
			for( i in 0...index )
				offset += INPUT_SIZE[i];
			c.setVertexBufferAt(i, pol.vbuf, offset, vformats[Tools.floatSize(inp.type)]);
		}
		
		// draw
		c.drawTriangles(pol.ibuf);
		
		// unbind
		for( i in 0...shaderInfos.input.length )
			c.setVertexBufferAt(i, null);
		for( i in 0...shaderInfos.fragment.tex.length )
			c.setTextureAt(i, null);
		
		c.present();
	}

	function error( ?msg : String, ?pmin : Int, ?pmax : Int ) {
		cnx.setError.call([msg,pmin,pmax]);
	}
	
	function hscriptError( e : hscript.Expr.Error ) {
		return switch( e.e ) {
		case EUnterminatedString: "unterminated string";
		case EUnterminatedComment: "unterminated comment";
		case EUnexpected(t): "unexpected " + t;
		case EUnknownVariable(v): "unknown variable " + v;
		case EInvalidOp(op): "invalid operation " + op;
		case EInvalidChar(c): "invalid char " + c;
		case EInvalidAccess(a): "invalid access " + a;
		case EInvalidIterator(v): "invalid iterator "+v;
		}
	}

	function compile( code : format.hxsl.Data.Code ) {
		var c = new format.agal.Compiler();
		c.error = function(msg, p) throw new format.hxsl.Data.Error(msg, p);
		var agal = c.compile(code);
		// print agal code
		var str = [];
		if( code.consts.length > 0 )
			str.push("// Constants : " + Std.string(code.consts));
		for( op in agal.code )
			str.push(format.agal.Tools.opStr(op));
		cnx.setValue.call(["agal_"+(code.vertex?"vertex":"fragment"), str.join("\n")]);
		// write agal bytes
		var bytes = new haxe.io.BytesOutput();
		var w = new format.agal.Writer(bytes);
		w.write(agal);
		var barr = bytes.getBytes().getData();
		barr.position = 0;
		return barr;
	}

	function updateHXSL( hxsl : String ) {
		var p = new hscript.Parser();
		p.allowTypes = true;
		var expr;
		var me = this;
		// parse script and convert it to haxe.Macro.expr
		try {
			var code = p.parseString(hxsl);
			var pos = { file : "hxsl", min : 0, max : 0 };
			expr = new hscript.Macro(pos).convert(code);
		} catch( e : hscript.Expr.Error ) {
			error("HxSL Error : " + hscriptError(e), e.pmin, e.pmax );
			return;
		}
		cnx.clearWarnings.call([]);
		try {
			// parse hxsl
			var p = new format.hxsl.Parser();
			var e = p.parse(expr);
						
			// compile it into intermediate code
			var c = new format.hxsl.Compiler();
			c.warn = function(msg, p) {
				me.cnx.addWarning.call([msg, p.min, p.max]);
			};
			var hxsl = c.compile(e);
			// compile it into AGAL
			var vbytes = compile(hxsl.vertex);
			var fbytes = compile(hxsl.fragment);
			
			// check input
			for( i in hxsl.input )
				if( !Lambda.has(INPUTS,i.name) )
					throw new format.hxsl.Data.Error("Unsupported input '" + i.name + "', please use one of the following : " + INPUTS.join(","), i.pos);
					
			// check variables
			for( i in hxsl.vertex.args.concat(hxsl.fragment.args) )
				if( !vars.exists(i.name) )
					throw new format.hxsl.Data.Error("Unknown variable '" + i.name + "'", i.pos);
			
			// build shader
			var shader = this.c.createProgram();
			try {
				shader.upload(vbytes, fbytes);
			} catch( e : Dynamic ) {
				shader.dispose();
				throw new format.hxsl.Data.Error(Std.string(e), null);
			}
			
			// setup variables
			for( v in hxsl.vertex.args.concat(hxsl.fragment.args).concat(hxsl.fragment.tex) ) {
			}
			
			if( this.shader != null ) this.shader.dispose();
			this.shader = shader;
			this.shaderInfos = hxsl;
		} catch( e : format.hxsl.Data.Error ) {
			if( e.pos == null )
				error("HxSL Compilation error : " + e.message);
			else
				error("HxSL Compilation error : " + e.message,e.pos.min,e.pos.max);
			return;
		}
		error();
	}
	
	static var INPUTS = ["pos", "norm", "uv"];
	static var INPUT_SIZE = [3, 3, 2];

	static var DEFAULT_HXSL = StringTools.trim("
var input : {
	pos : Float3,
	uv : Float2,
};

var tuv : Float2;

function vertex( mpos : M44, mproj : M44 ) {
	out = pos.xyzw * mpos * mproj;
	tuv = uv;
}

function fragment( tex : Texture, time : Float ) {
	out = tex.get(tuv) + [cos(time * 3),0,0,0];
}
");
	
	static var inst : Studio;
	static function main() {
		haxe.Log.setColor(0xFF0000);
		inst = new Studio(flash.Lib.current);
	}
}