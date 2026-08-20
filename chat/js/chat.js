var elVisitors = null;
var elMessages = null;
var elInput = null;
var elRecipient = null;
var ServerSideScriptURI = null;

var currentUserId = 0;

var intervalID = null;

var messageCount = 0;
var messageLimit = 120;

var bProcessing = false;
var checkInterval = 30000;
var Months = new Array ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');


var msgQueue = [];
msgQueue.add = msgQueue.push;
msgQueue.remove = msgQueue.shift;


function chatInit(ScriptURI, MessagesLimit) {
	ServerSideScriptURI = ScriptURI;
	messageLimit = MessagesLimit;
	elVisitors = document.getElementById('ChatVisitors');
	elMessages = document.getElementById('ChatMessages');
	elInput = document.getElementById('ChatInputLine');
	elColor = document.getElementById('ChatColor');
	elRecipient = document.getElementById('ChatRecipient');
	resizeContainers();
	chatFocusInput();
	chatDoLoad();
	chatStartSchedule();
}


function chatStartSchedule() {
	if( checkInterval > 0 ){
		if( intervalID ) {
			clearTimeout(intervalID);
		}
		intervalID = setInterval('chatDoLoad()', checkInterval);
	}
}


function chatStopSchedule(){
	// stop requests if user was not authorised
	if ( intervalID ) {
		clearTimeout(intervalID);
	}
	checkInterval = 0;
}


function chatDoLoad(){
	if(!chatIsLocked()){
		chatLock();
		setInterval('chatUnlock()', 15000); // even if process not finished force unlock it after 15 secs

		var text = (msgQueue.length) ? msgQueue.remove() : '';
		
		// create new object Subsys_JsHttpRequest
		var req = new JsHttpRequest();
		
		// when data load this code will start authomatically
		req.onreadystatechange = function() {
			if( req.readyState == 4 && req.responseJS ){
				chatLoadCompleate(req);
			}
		}
		
		// disable caching
		req.caching = false;

		// prepare object
		req.open(null, ServerSideScriptURI, true);

		// send request
		req.send( { 'text': text, 'last': chatGetLastMessageId(), 'recipient': chatGetRecipient(), 'color': chatGetColor() } );
	}
}


function chatLoadCompleate(req){
	// update chat messages and users
	if( currentUserId == 0 && req.responseJS.current ){
		currentUserId = req.responseJS.current.user_id;
	}
	chatRedraw(req.responseJS.visitors, req.responseJS.messages, req.responseJS.authors);

	chatUnlock();

	if( msgQueue.length ){
		chatDoLoad();
	} else {
		chatStartSchedule();
	}
}


function chatDoSendMessage(){
	// add message to a Queue
	msgQueue.add(chatGetInputValue());

	// clean input
	chatClearInputValue();
	chatFocusInput();

	// start sending process 
	chatDoLoad();
}


function chatGetInputValue(){
	return '' + elInput.value;
}

function chatSetInputValue(value){
	elInput.value = value;
}

function chatClearInputValue(){
	chatSetInputValue('');
}

function chatFocusInput(){
	elInput.focus();
}


function chatGetColor(){
	if( elColor.tagName == 'SELECT' ){
		return elColor.options[elColor.selectedIndex].value;
	} else {
		return elColor.getAttribute('rgb');
	}
}


function chatSetColor(color){
	if( elColor.tagName == 'SELECT' ){
	} else {
		elColor.style.color = color;
		elColor.setAttribute('rgb', color);
	}
}


function chatChooseColor(){
	alert(1);
}


function chatRedraw (visitors, messages, authors) {
	if( visitors ){
		chatRedrawVisitors(visitors, 0);
	}
	if( messages ){
		chatRedrawMessages(messages, authors);
	}
}


function chatLock() {
	bProcessing = true;
}


function chatUnlock() {
	bProcessing = false;
}

function chatIsLocked(){
	return bProcessing;
}


function chatRemoveChildren(el, limit) {
	var cnt = isNaN(parseInt(limit)) ? 65535 : parseInt(limit);
	while( el.firstChild && cnt > 0 ){
		el.removeChild(el.firstChild);
		cnt--;
	}
}


function chatBuildMessage(message, authors) {
	var elDiv = document.createElement('DIV');
	elDiv.setAttribute('id', message.id);
	elDiv.className = 'ChatMessage';
	
	if( message.id == 0 ){
		chatStopSchedule();
	}
	
	if( message.color != '' ){
		elDiv.style.color = message.color;
	}

	var elTime = document.createElement('SPAN');
	elTime.className = 'Time';
	elTime.appendChild(document.createTextNode('[' + chatPrintMessageDate(message.dt) + ']'));

	var elAuthor = document.createElement('SPAN');
	elAuthor.className = 'Author';

	var authorId = message.from_id;
	if( message.to_id == 0 ){
		var charBefore = '<';
		var charAfter = '>';
	} else {
		var charBefore = '';
		if( message.from_id == currentUserId ) {
			authorId = message.to_id;
			var charAfter = ':';
		} else {
			var charAfter = '>';
		}
	}
	var authorName = '';
	for(var i = 0; i < authors.length; i++ ){
		if( authors[i].id == authorId ){
			authorName = authors[i].name;
			break;
		}
	}
	var elAuthorName = document.createTextNode( charBefore + authorName + charAfter );
	elAuthor.appendChild(elAuthorName);

	elAuthor.setAttribute('id', authorId);
	elAuthor.setAttribute('visitor_name', authorName);
	elAuthor.onclick = visitorClick;

	var elMessageText = message.message;
	elMessageText = elMessageText.replace( new RegExp('<', 'g'), '&lt;');
	elMessageText = elMessageText.replace( new RegExp('>', 'g'), '&gt;');
	elMessageText = elMessageText.replace( new RegExp('((?:https?://|ftp://|mailto:)(?:[:a-zA-Z0-9_+~%{}./?=&@#\*-]+))', 'gi'), '<a href="$1">$1</a>');


	var elMessage = document.createElement('SPAN');
	elMessage.className = 'Text';
	elMessage.innerHTML = elMessageText;

	elDiv.appendChild(elTime);
	elDiv.appendChild(elAuthor);
	elDiv.appendChild(elMessage);
	
	return elDiv;
}


function chatBuildHref(sHref){
	var elA = document.createElement('A');
	elA.setAttribute('href', sHref);
	elA.appendChild(document.createTextNode(sHref));
	return elA;
}


function chatPrintMessageDate(date){
	var d = new Date( 1000 * date );
	return '' + d.getDate() + ' ' + Months[d.getMonth()] + ' ' + chatPrintTimeNumber( d.getHours() ) + ':' + chatPrintTimeNumber( d.getMinutes() );
}


function chatPrintTimeNumber(value){
	return ( value < 10 ) ? '0' + value : value;
}


function chatClearMessages() {
	chatRemoveChildren(elMessages);
}


function chatRedrawMessages(messages, authors){
	var n = messages.length;
	if( n > 0 ){
		var banned = chatGetBanned();
		var diff = 0;
		for(var i = 0; i < n; i++) {
			if( !isBanned(messages[i].user_id, banned) ){
				diff++;
			}
		}
		
		var bIsAtBottom = (elMessages.scrollTop > elMessages.scrollHeight - elMessages.clientHeight) ? true : false;
		var bIsFirstLoad = (messageCount == 0) ? true : false;
		if( diff > 0 ){
			messageCount = messageCount + diff;
			if( messageCount > messageLimit ){
				chatRemoveChildren(elMessages, messageCount - messageLimit);
				messageCount = messageLimit;
			}
			for(var i = 0; i < n; i++) {
				if( !isBanned(messages[i].user_id, banned) ){
					elMessages.appendChild(chatBuildMessage(messages[i], authors));
				}
			}
			if( bIsFirstLoad || bIsAtBottom ){
				elMessages.scrollTop = elMessages.scrollHeight - elMessages.clientHeight + 20;
			}
		}
	}
}



function chatBuildVisitor(visitor, banned){
	var elDiv = document.createElement('DIV');
	elDiv.className = 'ChatVisitor';
	elDiv.setAttribute('id', visitor.id);
	
	var disabled = false;
	if( visitor.id == currentUserId ){
		disabled = true;
	}

	if( document.all && !window.opera ){
		var addon = '';
		if( disabled ){
			addon = addon + ' disabled="disabled"';
		}
		if( !isBanned(visitor.id, banned) ){
			addon = addon + ' checked="checked"';
		}
		var elIn = document.createElement('<input type="checkbox" name="ChatIgnore" value="' + visitor.id + '"' + addon + ' />');
	} else {
		var elIn = document.createElement('INPUT');
		elIn.setAttribute('type', 'checkbox');
		elIn.setAttribute('name', 'ChatIgnore');
		elIn.setAttribute('value', visitor.id);
		elIn.disabled = disabled;
		elIn.checked = !isBanned(visitor.id, banned);
	}
	elDiv.appendChild(elIn);

	var elVisitor = document.createElement('SPAN');
	elVisitor.setAttribute('visitor_name', visitor.name);
	elVisitor.setAttribute('title', visitor.user_agent);

	if( visitor.id == currentUserId ){
		elVisitor.className = 'Name Current';
	} else {
		elVisitor.className = 'Name';
		elVisitor.onclick = visitorClick;
	}
	elVisitor.appendChild(document.createTextNode(visitor.name));

	elDiv.appendChild(elVisitor);
	
	return elDiv;
}


function chatSetRecipient(value){
	elRecipient.value = value;
}


function chatGetRecipient(){
	return elRecipient.value;
}


function chatClearRecipient(){
	chatSetRecipient('');
	chatFocusInput();
}


function chatGetLastMessageId(){
	var last_message_id = 0;
	if( elMessages.lastChild && elMessages.lastChild.id ){
		last_message_id = elMessages.lastChild.id;
	}
	return last_message_id;
}


function visitorClick(evt){
	var currElem = (evt)? evt.currentTarget : event.srcElement;
	chatSetRecipient(currElem.getAttribute('visitor_name'));
	chatFocusInput();
}


function chatClearVisitors() {
	chatRemoveChildren(elVisitors);
}


function chatRedrawVisitors(visitors){
	var n = visitors.length;
	if( n > 0 ){
		var banned = chatGetBanned();
		chatClearVisitors();
		for( var i = 0; i < n; i++ ) {
			elVisitors.appendChild( chatBuildVisitor(visitors[i], banned) );
		}
	}
}


function chatGetBanned(){
	var banned = new Array();
	var num = 0;
	var currElem = elVisitors.firstChild;
	while( currElem ) {
		if( currElem.firstChild && !currElem.firstChild.checked ) {
			banned[num] = currElem.firstChild.value;
			num++;
		}
		currElem = currElem.nextSibling
	}
	return banned;
}


function isBanned(visitor_id, banned) {
	var r = false;
	for( var j = 0; j < banned.length; j++ ){
		if( banned[j] == visitor_id ){
			r = true;
		}
	}
	return r;
}


function resizeContainers() {
	elVisitors.style.height = elMessages.style.height = getWindowHeight() - 80;
	elInput.style.width = elMessages.offsetWidth - elRecipient.offsetWidth;
}


function getWindowHeight() {
	return self.innerHeight || document.body.clientHeight || document.documentElement.clientHeight;
}


window.onresize = resizeContainers;