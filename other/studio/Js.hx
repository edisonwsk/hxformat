class Js {

	var cnx : haxe.remoting.Connection;
	var hxsl : js.Dom.Textarea;
	var lasthxsl : String;
	
	public function new() {
		var ctx = new haxe.remoting.Context();
		ctx.addObject("api", this);
		cnx = haxe.remoting.ExternalConnection.flashConnect("cnx", "swf_studio", ctx).api;
	}
	
	function get(id) {
		return js.Lib.document.getElementById(id);
	}
	
	function setError(msg,?pmin:Int,?pmax:Int) {
		var e = get("error");
		if( msg == null ) {
			e.style.display = "none";
			return;
		}
		e.innerHTML = StringTools.htmlEscape(msg);
		e.style.display = "";
		var me = this;
		e.onclick = function(_) {
			if( pmin == null ) {
				js.Lib.alert("No code position available for this error");
				return;
			}
			me.select(pmin, pmax);
		};
	}
	
	function select(pmin, pmax) {
		new js.Selection(hxsl).select(pmin, pmax + 1);
	}
	
	function onFlashInit(hxsl) {
		var me = this;
		this.hxsl.value = hxsl;
		this.hxsl.onkeyup = function(_) me.checkChanges();
		// setup regular check if hxsl changes
		var check = new haxe.Timer(50);
		check.run = checkChanges;
	}
	
	function checkChanges() {
		var hxsl = hxsl.value;
		if( hxsl != lasthxsl ) {
			lasthxsl = hxsl;
			cnx.updateHXSL.call([hxsl]);
		}
	}
	
	function clearWarnings() {
		var w = get("warnings");
		w.innerHTML = "";
		w.style.display = "none";
	}
	
	function addWarning( msg, pmin, pmax ) {
		var w = get("warnings");
		w.innerHTML += '<li><a href="#" onclick="_.select('+pmin+','+pmax+'); return false">' + StringTools.htmlEscape(msg) + '</a></li>';
		w.style.display = "";
	}
	
	function setValue( id : String, value : String ) {
		var e = cast get(id);
		e.value = value;
	}
	
	function init(_) {
		setTab("hxsl");
		setError(null);
		
		// check that the SWF loads correctly
		var check = new haxe.Timer(1000);
		var me = this;
		check.run = function() {
			check.stop();
			if( me.hxsl.value == "" )
				me.setError("HxSL Studio requires Flash 11 Beta Player, please download it from http://labs.adobe.com");
		};
		
		// load SWF
		var swf = new js.SWFObject("studio.swf", "swf_studio", 450, 450, "9", "#FFFFFF");
		swf.addParam("scale", "noscale");
		swf.addParam("wmode", "gpu");
		swf.write("flash");
		hxsl = cast get("hxsl");
	}
	
	function setTab(name) {
		for( t in ["hxsl","agal","help"] ) {
			get("t_" + t).style.display = (t == name) ? "" : "none";
			get("l_" + t).className = (t == name) ? "active" : "";
		}
	}
	
	static var inst : Js;
	public static function main() {
		inst = new Js();
		js.Lib.window.onload = inst.init;
		Reflect.setField(js.Lib.document, "_", inst);
	}
	
}