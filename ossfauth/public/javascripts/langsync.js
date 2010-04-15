if(!$sso) var $sso = {};

(function(sso){
  sso.langCookies = {openfoundry:'lang', wsw:'mbfcookie[lang]'};
  sso.langs = ['en', 'zh_TW']; 
  
  sso.createCookie = function(name,value,days) {
    if (days) {
      var date = new Date();
      date.setTime(date.getTime()+(days*24*60*60*1000));
      var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = name+"="+value+expires+"; path=/";
  }

  sso.getLang = function() {
    var lang = '';
    lang = location.search.match(/[&|?]lang=([^&]*)/,'');
    if(!lang) lang=""; else lang=lang[1]; 
    for (var i in this.langs)
    {
      if(location.pathname.match("/"+this.langs[i]+"/")) return(this.langs[i]); 
      if(lang == this.langs[i]) return(this.langs[i]);
    }
    return(""); 
  }
  
  sso.langSync = function(lang) {
    if(this.langs.indexOf(lang) < 0) return(0);

    for (var l in this.langCookies)
    {
      this.createCookie(this.langCookies[l], lang, '');
    }
    return(1);
  }
  
  sso.langAutoSync = function() {
    this.langSync(this.getLang());
  }
})($sso);

$sso.langAutoSync();
