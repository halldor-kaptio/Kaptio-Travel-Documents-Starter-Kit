function initDocument(){

    jQuery('#ktContentOutput').html(content);
    jQuery('.fancybox').fancybox();
    jQuery('.fancybox-media').fancybox({
        openEffect  : 'none',
        closeEffect : 'none',
        helpers : {
            media : {}
        }
    });
    initKTAgengaViewUI(); // It is a common method for Content Editor and Customer output (from OutputResources.page)

    //init image gallery for content placeholders
    jQuery('.cp-media').lightGallery({
        hash:false,
        loadYoutubeThumbnail:false,
        loadVimeoThumbnail:false,
        selector: '.cp-image'
    });
}

function setNavbar() {
    //console.log('setNavbar_START');
    var kaptioNavbar = $('ul.nav-tabs');
    var kaptioNavbarItems = kaptioNavbar.children().children();
    //console.log("KT ~ file: KT_Scripts.page ~ line 8 ~ setNavbar ~ kaptioNavbarItems", kaptioNavbarItems)


    var count = 0;
    for (var i = 0; i < kaptioNavbarItems.length; i++) {
        var currentLink = kaptioNavbarItems[i];
        var style = (count == 0) ? 'class="active"' : '';
        count++;

        if ($.trim($(currentLink.getAttribute('href')).text()) != '' && $.trim($(currentLink.getAttribute('href')).text()) != currentLink.innerText) {
            $("#navbar").append('<li ' + style + '><a href="' + currentLink.getAttribute('href') + '" aria-controls="' + currentLink.getAttribute('aria-controls') + '" role="tab" data-toggle="tab" aria-expanded="true">' + currentLink.innerHTML + '</a></li>');
        }
    }

    kaptioNavbar.remove();
    setNavbarBehavior();
}

function setNavbarBehavior() {
    //Navigation Sidebar
    var $ = jQuery.noConflict();
    $('nav ul li a').click(function () {
        
        $('.fixed-tabs-content').children('.tab-pane').removeClass('active');
        $("#summary-box-actions:hidden").css("display", "block");
        $("#pricing-contact-info:visible").css("display", "none");
        scrollToElement('content');

        if ($('.dtd-toggle').hasClass('ta-open')) {
            $('.dtd-toggle').removeClass('ta-open');
            $('.dtd-toggle').addClass('ta-close');
            $('.dtd-toggle').next('.detailed-info-container').addClass('hidden');

        }
    });
}

function setCollapsedListBehavior() {
    // Accordion Open/Close
    var $ = jQuery.noConflict();
    $('.dtd-toggle').on('click', function () {
        

        var $this = $(this);
        var $others = $('.dtd-toggle').not(this);

        $this.toggleClass('ta-open ta-close');
        $this.next('.detailed-info-container').toggleClass('hidden');

        if ($others.hasClass('ta-open')) {
            $others.removeClass('ta-open');
            $others.addClass('ta-close');
            $others.next('.detailed-info-container').addClass('hidden');

            scrollToElement($(this).attr('id'));
        }
    });
}

// Scroll to functionality
function scrollToElement(selector) {
    var $ = jQuery.noConflict();
    var targetOffset = $('#' + selector).offset().top - 70;

    $('html, body').animate({
        scrollTop: targetOffset
    }, 1000);
};


function showMenuLogo(){

    var $ = jQuery.noConflict();
    var distance = $('nav').offset().top;

    $(window).scroll(function() {
        if ( $(this).scrollTop() >= distance ) {
            if( !$('.menu-logo').hasClass('visible')){
                $('.menu-logo').addClass('visible');
            }            
        } else {
            if($('.menu-logo').hasClass('visible')){
                $('.menu-logo').removeClass('visible');
            }          
        }
    });
}

function closeMobileMenuOnClick(){
    var $ = jQuery.noConflict();

    $('.nav-Horizontal nav a').on('click',function(){
        $('.nav-Horizontal .nav-toggle').click();
    });
}

/* Core Functions */

function initKTAgengaViewUI() {
    jQuery('.kt-agenda-content-data').each(function(){
        var pid = jQuery(this).data('kt-agenda-id');
        
        var block = {};
        block.$$ = jQuery('.kt-agenda-content-id-'+pid).parent();
        
        block.$ = function(el) {
            return this.$$.find(el);
        }
        var JSONtext = JSON.parse(jQuery(this).text());
        
        initKTAgendaData(block, JSONtext, false);
        ktAgenda_customInitHandler(block);
    });
}

Handlebars.registerHelper('compare', function (lvalue, operator, rvalue, options) {
    var operators, result;
    if (arguments.length < 3) {
        throw new Error("Wrong parameters number"); // internal dev error message
    }
    if (options === undefined) {
        options = rvalue;
        rvalue = operator;
        operator = "===";
    }
    operators = {
        '==': function (l, r) { return l == r; },
        '===': function (l, r) { return l === r; },
        '!=': function (l, r) { return l != r; },
        '!==': function (l, r) { return l !== r; },
        '<': function (l, r) { return l < r; },
        '>': function (l, r) { return l > r; },
        '<=': function (l, r) { return l <= r; },
        '>=': function (l, r) { return l >= r; },
        'typeof': function (l, r) { return typeof l == r; },
        'in': function (l, r) {
            var llist = r.split(",");
            return llist.indexOf(l) > -1;
        }
    };
    if (!operators[operator]) {
        throw new Error("Handlerbars Helper 'compare' doesn't know the operator " + operator); // internal dev error message
    }
    result = operators[operator](lvalue, rvalue);
    if (result) {
        return options.fn(this);
    } else {
        return options.inverse(this);
    }
});

var userDateFormat = getDateFormatString();

function getDateFormatString(){
    var dtf = UserContext.dateFormat;
    var result = '';
    // convert lowercase d and y to uppercase to work with moment.js
    for( var i = 0; i<dtf.length; i++){
        var c = dtf[i];
        if( c == 'd' || c == 'y' ){
            c = c.toUpperCase();
        }
        result += c;
    }
    return result;
}

function showProcess() {
    jQuery('.content-editor-processing').removeClass('c-hidden');
}

function hideProcess() {
    jQuery('.content-editor-processing').addClass('c-hidden');
}