all:
	haxe studio.hxml
	
deploy: all
	rsync -avz --delete index.htm studio.js studio.swf ncannasse@ncannasse.fr:/data/ncannasse.fr/www/file/studio/