var Presentation = {
    init : function(option){
        this.size = 9;

        this._offset  = 0;
        this.canvas   = document.getElementById('canvas');
        this.content  = document.getElementById('content');
        this.textbox  = document.getElementById('textField');
        this.deck     = document.getElementById('deck');
        this.scroller = document.getElementById('scroller');

        this.toolbar         = document.getElementById('canvasToolbar');
        this.toolbarHeight   = this.toolbar.boxObject.height;
        this.isToolbarHidden = true;
        this.toolbar.setAttribute('style', 'margin-top:'+(0-this.toolbarHeight)+'px;margin-bottom:0px;');

        if(option){
            for(var i in option){this[i] = option[i]}
        }

        if (this.readParameter()) {
            this.takahashi();
        }

        document.documentElement.focus();
    },

    takahashi : function(){
        if (!document.title)
            document.title = this.data[0].replace(/[\r\n]/g, ' ');

        if(!this.data[this.offset]){
            this.offset = this.data.length-1;
        }
        document.getElementById("current_page").value = this.offset+1;
        document.getElementById("max_page").value     = this.data.length;

        this.scroller.setAttribute('maxpos', this.data.length-1);
        this.scroller.setAttribute('curpos', this.offset);

        var broadcaster = document.getElementById('canBack');
        if (!this.offset)
            broadcaster.setAttribute('disabled', true);
        else
            broadcaster.removeAttribute('disabled');

        var broadcaster = document.getElementById('canForward');
        if (this.offset == this.data.length-1)
            broadcaster.setAttribute('disabled', true);
        else
            broadcaster.removeAttribute('disabled');

        this.canvas.setAttribute('rendering', true);

        var text = this.data[this.offset].
                replace(/^[\r\n]+/g,"").replace(/[\r\n]+$/g,"").replace(/(\r\n|[\r\n])/g,"\n")
                .split('\n');
        var range = document.createRange();
        range.selectNodeContents(this.content);
        range.deleteContents();
        range.detach();

        var line;
        var newLine;
        var uri;
        var image_width;
        var image_total_width  = 0;
        var image_height;
        var image_total_height = 0;
        var image_src;

        var labelId = 0;

        for (var i = 0; i < text.length; i++)
        {
            this.content.appendChild(document.createElement('hbox'));
            this.content.lastChild.setAttribute('align', 'center');
            this.content.lastChild.setAttribute('pack', 'center');

            line = text[i];
            image_width  = 0;
            image_height = 0;

            if (line.match(/^ /)) {
              this.content.lastChild.setAttribute('align', 'left');
              this.content.lastChild.setAttribute('class', 'pre');
              line = line.substring(1)
            }

            while (line.match(/^([^\{]+)?(\{\{ima?ge? +src="([^"]+)" +width="([0-9]+)" +height="([0-9]+)"[^\}]*\}\}|\{\{(([^\|]+)?\||)(.+?)\}\})(.+)?/))
            {
                if (RegExp.$1) {
                    this.content.lastChild.appendChild(document.createElement('description'));
                    this.content.lastChild.lastChild.setAttribute('value', RegExp.$1);
                }
                newLine = line.substring((RegExp.$1+RegExp.$2).length);

                // Images
                if (/^([^\{]+)?\{\{ima?ge? +src="([^"]+)" +width="([0-9]+)" +height="([0-9]+)"[^\}]*\}\}/.test(line)) {
                    this.content.lastChild.appendChild(document.createElement('image'));
                    image_src = RegExp.$2;
                    if (image_src.indexOf('http://') < 0 &&
                        image_src.indexOf('https://') < 0)
                        image_src = this.dataFolder+image_src;
                    this.content.lastChild.lastChild.setAttribute('src', image_src);
                    this.content.lastChild.lastChild.setAttribute('width', parseInt(RegExp.$3 || '0'));
                    this.content.lastChild.lastChild.setAttribute('height', parseInt(RegExp.$4 || '0'));
                    image_width  += parseInt(RegExp.$3 || '0');
                    image_height = Math.max(image_height, parseInt(RegExp.$4 || '0'));
                }

                // Styles
                // else if (/^([^\{]+)?\{\{#([^\|]+)\|([^\}]+)\}\}/.test(line)) {
                else if (/^([^\{]+)?\{\{(#([^\|]+)?\|)(.+?)\}\}/.test(line)) {
                    uri = RegExp.$4;
                    this.content.lastChild.appendChild(document.createElement('description'));
                    this.content.lastChild.lastChild.setAttribute('value', uri);
                    this.content.lastChild.lastChild.setAttribute('class', RegExp.$3);
                }

                // Links
                else if (/^([^\{]+)?\{\{(([^\|]+)?\||)([^\}]+)\}\}/.test(line)) {
                    uri = RegExp.$4;
                    if (uri.indexOf('://') < 0)
                        uri = this.dataFolder+uri;
                    this.content.lastChild.appendChild(document.createElement('description'));
                    this.content.lastChild.lastChild.setAttribute('value', RegExp.$3 || RegExp.$4);
                    this.content.lastChild.lastChild.setAttribute('href', uri);
                    this.content.lastChild.lastChild.setAttribute('tooltiptext', uri);
                    this.content.lastChild.lastChild.setAttribute('statustext', uri);
                    this.content.lastChild.lastChild.setAttribute('class', 'link-text');
                }

                line = newLine;
            }

            if (line) {
                this.content.lastChild.appendChild(document.createElement('description'));
                this.content.lastChild.lastChild.setAttribute('value', line);
            }

            image_total_width = Math.max(image_total_width, image_width);
            image_total_height += image_height;
        }

        this.content.setAttribute('style', 'font-size:10px;');

        if (this.content.boxObject.width) {
            var canvas_w  = this.canvas.boxObject.width;
            var canvas_h  = this.canvas.boxObject.height-image_total_height;

            var content_w = this.content.boxObject.width;
            var new_fs = Math.round((canvas_w/content_w) * this.size);
            this.content.setAttribute('style', 'font-size:'+ new_fs + "px");

            if (this.content.boxObject.width < image_total_width) {
                content_w = image_total_width;
                new_fs = Math.round((canvas_w/content_w) * this.size);
                this.content.setAttribute('style', 'font-size:'+ new_fs + "px");
            }

            var content_h = this.content.boxObject.height;
            if(content_h >= canvas_h){
                content_h = this.content.boxObject.height;
                new_fs = Math.round((canvas_h/content_h) * new_fs);
                this.content.setAttribute('style', 'font-size:'+ new_fs + "px");
            }
        }

        this.canvas.removeAttribute('rendering');
    },

    reload : function() {
        if (this.dataPath != location.href) {
            var path = this.dataPath;
            if (location.href.match(/^https?:/)) {
                var request = new XMLHttpRequest();
                request.open('GET', path);
                request.onload = function() {
                    Presentation.textbox.value = request.responseText;
                    Presentation.data = Presentation.textbox.value.split('----');

                    Presentation.takahashi();

                    path = null;
                    request = null;
                };
                request.send(null);
            }
            else {
                document.getElementById('dataLoader').setAttribute('src', 'about:blank');
                window.setTimeout(function() {
                    document.getElementById('dataLoader').setAttribute('src', path);
                    path = null;
                }, 10);
            }
        }
        else
            window.location.reload();
    },

    forward : function(){
        this.offset++;
        this.takahashi();
    },
    back : function(){
        this.offset--;
        if(this.offset < 0){this.offset = 0}
        this.takahashi();
    },
    home : function(){
        this.offset = 0;
        this.takahashi();
    },
    end : function(){
        this.offset = this.data.length-1;
        this.takahashi();
    },
    showPage : function(aPageOffset){
        this.offset = aPageOffset ? aPageOffset : 0 ;
        this.takahashi();
    },

    addPage : function() {
        if (this.textbox.value &&
            !this.textbox.value.match(/(\r\n|[\r\n])$/))
            this.textbox.value += '\n';
        this.textbox.value += '----\n';
        this.onEdit();
    },

    toggleEditMode : function(){
        this.deck.selectedIndex = (this.deck.selectedIndex == 0) ? 1 : 0 ;
    },
    toggleEvaMode : function(){
        var check = document.getElementById('toggleEva');
        if (this.canvas.getAttribute('eva') == 'true') {
            this.canvas.removeAttribute('eva');
            check.checked = false;
        }
        else {
            this.canvas.setAttribute('eva', true);
            check.checked = true;
        }
    },

    onPresentationClick : function(aEvent){
        if (!this.isToolbarHidden)
            this.showHideToolbar();

        switch(aEvent.button)
        {
            case 0:
                var uri = aEvent.target.getAttribute('href');
                if (uri)
                    window.open(uri);
                else {
                    this.forward();
                    document.documentElement.focus();
                }
                break;
            case 2:
                this.back();
                document.documentElement.focus();
                break;
            default:
                break;
        }
    },
    onScrollerDragStart : function(){
        this.scroller.dragging = true;
    },
    onScrollerDragMove : function(){
        if (this.scroller.dragging)
            this.showPage(parseInt(this.scroller.getAttribute('curpos')));
    },
    onScrollerDragDrop : function(){
        if (this.scroller.dragging) {
            this.showPage(parseInt(this.scroller.getAttribute('curpos')));
        }
         this.scroller.dragging = false;
    },
    onEdit : function() {
        this.data = this.textbox.value.split('----');
        this.takahashi();
    },

    onKeyPress : function(aEvent) {
        switch(aEvent.keyCode)
        {
            case aEvent.DOM_VK_BACK_SPACE:
                if (this.isPresentationMode) {
                    aEvent.preventBubble();
                    aEvent.preventDefault();
                    Presentation.back();
                }
                break;
            default:
                break;
        }
    },


    onToolbarArea   : false,
    toolbarHeight   : 0,
    toolbarDelay    : 300,
    toolbarTimer    : null,
    isToolbarHidden : false,
    onMouseMoveOnCanvas : function(aEvent) {
        if (this.scroller.dragging) return;

        this.onToolbarArea = (aEvent.clientY < this.toolbarHeight);

        if (this.isToolbarHidden == this.onToolbarArea) {
            if (this.toolbarTimer) window.clearTimeout(this.toolbarTimer);
            this.toolbarTimer = window.setTimeout('Presentation.onMouseMoveOnCanvasCallback()', this.toolbarDelay);
        }
    },
    onMouseMoveOnCanvasCallback : function() {
        if (this.isToolbarHidden == this.onToolbarArea)
            this.showHideToolbar();
    },

    toolbarAnimationDelay : 100,
    toolbarAnimationSteps : 5,
    toolbarAnimationInfo  : null,
    toolbarAnimationTimer : null,
    showHideToolbar : function()
    {
        if (this.toolbarAnimationTimer) window.clearTimeout(this.toolbarAnimationTimer);

        this.toolbarAnimationInfo = { count : 0 };
        if (this.isToolbarHidden) {
            this.toolbarAnimationInfo.start = 0;
            this.toolbarAnimationInfo.end   = this.toolbarHeight;
        }
        else {
            this.toolbarAnimationInfo.start = this.toolbarHeight;
            this.toolbarAnimationInfo.end   = 0;
        }
        this.toolbarAnimationInfo.current = 0;

        this.toolbar.setAttribute('style', 'margin-top:'+(0-(this.toolbarHeight-this.toolbarAnimationInfo.start))+'px; margin-bottom:'+(0-this.toolbarAnimationInfo.start)+'px;');

        this.toolbarAnimationTimer = window.setTimeout('Presentation.animateToolbar()', this.toolbarAnimationDelay/this.toolbarAnimationSteps);
    },
    animateToolbar : function()
    {
        this.toolbarAnimationInfo.current += parseInt(this.toolbarHeight/this.toolbarAnimationSteps);

        var top, bottom;
        if (this.toolbarAnimationInfo.start < this.toolbarAnimationInfo.end) {
            top    = this.toolbarHeight-this.toolbarAnimationInfo.current;
            bottom = this.toolbarAnimationInfo.current;
        }
        else {
            top    = this.toolbarAnimationInfo.current;
            bottom = this.toolbarHeight-this.toolbarAnimationInfo.current;
        }

        top    = Math.min(Math.max(top, 0), this.toolbarHeight);
        bottom = Math.min(Math.max(bottom, 0), this.toolbarHeight);

        this.toolbar.setAttribute('style', 'margin-top:'+(0-top)+'px; margin-bottom:'+(0-bottom)+'px');

        if (this.toolbarAnimationInfo.count < this.toolbarAnimationSteps) {
            this.toolbarAnimationInfo.count++;
            this.toolbarAnimationTimer = window.setTimeout('Presentation.animateToolbar()', this.toolbarAnimationDelay/this.toolbarAnimationSteps);
        }
        else
            this.isToolbarHidden = !this.isToolbarHidden;
    },



    get offset(){
        return this._offset;
    },
    set offset(aValue){
        this._offset = parseInt(aValue || 0);
        document.documentElement.setAttribute('lastoffset', this.offset);
        return this.offset;
    },

    get data(){
        if (!this._data) {
             // Make sure you break the text into parts smaller than 4096
             // characters, and name them as indicated. Tweak as required.
             // (What a hack. A JS programmer should find a better way.)
             // Luc St-Louis, and email is lucs@pobox.com.

                 nodes = document.getElementById('builtinCode').childNodes;
                 content = '';
                for (i in nodes) {
                    if (nodes[i].nodeValue) {
                    content = content + nodes[i].nodeValue;
                    }
                }
    
               this._data = content.split("----");
        }

        return this._data;
    },
    set data(aValue){
        this._data = aValue;
        return aValue;
    },


    get isPresentationMode(){
        return (this.deck.selectedIndex == 0);
    },


    get dataPath(){
        if (!this._dataPath)
            this.dataPath = location.href;
        return this._dataPath;
    },
    set dataPath(aValue){
        var oldDataPath = this._dataPath;
        this._dataPath = aValue;
        if (oldDataPath != aValue) {
            this._dataFolder = this._dataPath.split('?')[0].replace(/[^\/]+$/, '');
        }
        return this._dataPath;
    },

    get dataFolder(){
        if (!this._dataFolder)
            this.dataPath = this.dataPath;
        return this._dataFolder;
    },
    set dataFolder(aValue){
        this._dataFolder = aValue;
        return this._dataFolder;
    },

    readParameter : function() {
        if (location.search) {
            var param = location.search.replace(/^\?/, '');

            if (param.match(/page=([0-9]+)/i))
                this.offset = parseInt(RegExp.$1)-1;

            if (param.match(/edit=(1|true|yes)/i))
                this.toggleEditMode();

            if (param.match(/eva=(1|true|yes)/i))
                this.toggleEvaMode();

            if (param.match(/data=([^&;]+)/i)) {
                var path = unescape(RegExp.$1);
                this.dataPath = path;
                if (location.href.match(/^https?:/)) {
                    var request = new XMLHttpRequest();
                    request.open('GET', path);
                    request.onload = function() {
                        Presentation.textbox.value = request.responseText;
                        Presentation.data = Presentation.textbox.value.split('----');

                        Presentation.takahashi();
                    };
                    request.send(null);
                }
                else {
                    document.getElementById('dataLoader').setAttribute('src', path);
                }
                return false;
            }
        }
        return true;
    },
    onDataLoad : function() {
        if (!window.frames[0].document.body.hasChildNodes()) return;
        var data = window.frames[0].document.body.firstChild.innerHTML;
        if (!data) return;

        this.textbox.value = data;
        this.data = this.textbox.value.split('----');

        this.takahashi();
    }
};

function init()
{
    window.removeEventListener('load', init, false);

    Presentation.init();
}
window.addEventListener('load', init, false);
