window.onload = Init

var Page

function Init()
{
	Page = new Page()
}


function Page()
{
	var i
	var elems = document.getElementsByTagName('textarea')
	for( i=0; i<elems.length; i++ )
	{
		if( elems[i].className.indexOf('Enlargable') != -1 )
		{
			elems[i].onfocus = this.EnlargeTextarea
			elems[i].onblur = this.RestoreTextarea
		}
	}

	return this
}


Page.prototype.EnlargeTextarea = function( evt )
{
	var elem = evt ? evt.target : event.srcElement
	if( elem )
	{
		elem.style.height = '40em'
	}
}


Page.prototype.RestoreTextarea = function ( evt )
{
	var elem = evt ? evt.target : event.srcElement
	if( elem )
	{
		elem.style.height = ''
	}
}


Page.prototype.ShowModal = function ( url, w, h )
{
	var name = 'Modal' + Math.floor( Math.random()*1000 )
	var width = w ? w : 600
	var height = h ? h : screen.height - 300

	var left = Math.round( (screen.width-width)/2 )
	var top =  Math.round( (screen.height-height)/2 ) - 35

	var options = 'status=yes,menubar=no,toolbar=no'
	options += ',resizable=yes,scrollbars=yes,location=no'
	options += ',width='  + width
	options += ',height=' + height
	options += ',left='   + left
	options += ',top='    + top

	var win = window.open( url, name, options )
	win.focus()

	return win

}
