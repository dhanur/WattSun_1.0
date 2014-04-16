var serach_flag=0;

function searchAndHighlight(searchTerm, selector) {
    if (searchTerm) {
        //var wholeWordOnly = new RegExp("\\g"+searchTerm+"\\g","ig"); //matches whole word only
        //var anyCharacter = new RegExp("\\g["+searchTerm+"]\\g","ig"); //matches any word with any of search chars characters
        var selector = selector || "#content_wrapper"; //use body as selector if none provided
        var searchTermRegEx = new RegExp(searchTerm, "ig");
        var matches = $(selector).text().match(searchTermRegEx);
        if (matches != null && matches.length > 0) {
            $('.highlighted').removeClass('highlighted'); //Remove old search highlights  

            //Remove the previous matches
            $span = $('#content_wrapper span');
            $span.replaceWith($span.html());
            
            $(selector).html($(selector).html().replace(searchTermRegEx, "<span class='match'>" + searchTerm + "</span>"));
            $('.match:first').addClass('highlighted');
            
            var i=0;
            
        	 $(window).bind('keypress', function(e) {
				 if (e.keyCode == 13) {
		          i++;
                  if(i >= $('.match').length)
                    i=0;
                
                $('.match').removeClass('highlighted');
                $('.match').eq(i).addClass('highlighted');                
              }        
             });


            if ($('.highlighted:first').length) { //if match found, scroll to where the first one appears
                $(window).scrollTop($('.highlighted:first').position().top);
            }
            return true;
        }
    }
    return false;
}
        alert(serach_flag);
         if (serach_flag==0)
         {
               	$(window).bind('keypress', function(e) {
               	               	
				if (e.keyCode == 13) {
				    $(".highlighted").removeClass("highlighted").removeClass("match");
                   if (!searchAndHighlight($('.textSearchvalue_h').val())) {
                   	serach_flag=1;	
                   alert("No results found");
     			}
 	
 			 }
			});
        	}		