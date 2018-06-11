App = this.App || {};

App.admin_ad_sources = {
  setup: function() {
    this.sharedBehaviour();
  },

  comments: function() {
    App.admin_ad_sources.newadSourceCommentTriggers();
    App.admin_ad_sources.adSourceComments();
  },

  newadSourceCommentTriggers: function() {
    $('#new-adsource-comment-trigger').on('click', function() {
      $(this).addClass('hidden');
      $('#new-adsource-comment').removeClass('hidden');
    });

    $('.cancel-new-adsource-comment-trigger').on('click', function() {
      $('#new-adsource-comment-trigger').removeClass('hidden');
      $('#new-adsource-comment').addClass('hidden');
      $('#new-adsource-comment').find('form')[0].reset();
      $(this).parents('.ad-source-comment').find('.list-group-item-text.hidden').removeClass('hidden');
      $(this).parents('.ad-source-comment').find('form').remove();
    });
  },

  adSourceComments: function() {
    $('#all-ad-source-comments-trigger').on('click', function() {
      if ($('.list-group-item').not('.recent-comment').first().attr('style') == undefined) {
        $('.list-group-item').not('.recent-comment').show();
        $(this).html('Show only recent comments');
      } else {
        $('.list-group-item').not('.recent-comment').removeAttr('style');
        $(this).html('Show all comments');
      }
    });
  },

  sharedBehaviour: function() {
  },

  list_assignments: function() {
    $(function(){
      $("#list-assignments-table thead th").data("sorter", false);

      $("#list-assignments-table").tablesorter({
        widgets: ['stickyHeaders'],
        headers : { 0 : { sorter: false } }
      });

      $('#filter').focus();
    });
  },

  simple_table_sorter: function() {
    $(".tablesorter thead th").data("sorter", false);

    $(".tablesorter").tablesorter({
      theme: 'bootstrap',
      headerTemplate: '{content}{icon}',
      widgets: ['uitheme','stickyHeaders']
    });
  },

  player_sizes: function() {
    App.admin_ad_sources.simple_table_sorter();
  },

  waterfalls: function() {
    App.admin_ad_sources.tablesorter();
  },

  bag_of_tags: function() {
    App.admin_ad_sources.tablesorter();
  },

  tablesorter: function(){
    $(".tablesorter").tablesorter({
      theme: 'bootstrap',
      headerTemplate: '{content}{icon}',
      widgets: ['uitheme','stickyHeaders']
    });
    $.extend($.tablesorter.themes.bootstrap, {
      iconSortAsc: 'glyphicon glyphicon-chevron-up',
      iconSortDesc: 'glyphicon glyphicon-chevron-down'
    });
  },

  list: function() {
    $(function(){
      $('#filter').focus();
    });
  },

  index: function() {
    $(function(){
      $('[data-toggle="popover"]').popover({container: 'body'});
    });
  },

  edit: function() {
    $(function() {

      $('#ad_source_player_size_id').change(function(){
        if($(this).val() == '4') {
          $('.pixel-sizes').show();
        } else {
          $('.pixel-sizes').hide();
        }
      });

      $('#ad_source_abstract_tag').change(function(){
        if($(this).attr('checked')) {
          $("#ad_source_dbam_symbol").attr('disabled',null);
          $("#ad_source_dbam_symbol_children").show();
        } else {
          $("#ad_source_dbam_symbol").attr('value','');
          $("#ad_source_dbam_symbol").attr('disabled','disabled');
          $("#ad_source_dbam_symbol_children").hide();
        };
      })
    })
  },

  tableSorter: function(deepLink, ad_source_path, root_url) {
    var lastAjaxURL = false;
    var pagerConfig = App.admin_ad_sources.pagerConfig(deepLink, ad_source_path, root_url);
    var yn_filter = {
      "Y" : function(e, n, f, i, $r, c, data) { return e == 'Y'; },
      "N" : function(e, n, f, i, $r, c, data) { return e == 'N'; },
    };

    var player_size_filter = {
      "None" : function(e, data) { return '0'; },
      "Small, Medium, Large" : function(e, data) { return '1'; },
      "Medium, Large" : function(e, data) { return '2'; },
      "Large" : function(e, data) { return '3'; },
      "Pixel Sizes" : function(e, data) { return '4'; },
      "Don't Know" : function(e, data) { return '5'; }
    }

    $(".tablesorter").tablesorter({
      theme: 'bootstrap',
      headerTemplate: '{content} {icon}',
      widgets: ['uitheme','filter', 'storage'],
      widgetOptions: {
        filter_cssFilter: "form-control",
        serverSideSorting: true,
        filter_functions: {
          3 : yn_filter,
          4 : yn_filter,
          5 : yn_filter,
          2 : {
            "Desktop - Dual VPAID"    : function(e, n, f, i, $r, c, data) { return n == f; },
            "Desktop - Flash VPAID"   : function(e, n, f, i, $r, c, data) { return n == f; },
            "Desktop - JS VPAID"      : function(e, n, f, i, $r, c, data) { return n == f; },
            "Desktop - Vast Only"     : function(e, n, f, i, $r, c, data) { return n == f; },
            "Mobile App - JS VPAID"   : function(e, n, f, i, $r, c, data) { return n == f; },
            "Mobile App - Vast Only"  : function(e, n, f, i, $r, c, data) { return n == f; },
            "Mobile Web - JS VPAID"   : function(e, n, f, i, $r, c, data) { return n == f; },
            "Mobile Web - Vast Only"  : function(e, n, f, i, $r, c, data) { return n == f; },
            "OTT - Vast Only"         : function(e, n, f, i, $r, c, data) { return n == f; }
          }
        }
      }
    }).tablesorterPager(pagerConfig);

    $.extend($.tablesorter.themes.bootstrap, {
      iconSortAsc: 'fa fa-chevron-up',
      iconSortDesc: 'fa fa-chevron-down',
    });
  },

  pagerConfig: function(deepLink, ad_source_path, root_url) {
    return {
      container: $(".pager"),
      ajaxUrl: ad_source_path+'.json?page={page}&{filterList:filter}&{sortList:column}&per={size}',
      customAjaxUrl: function(table, url) {
        if (deepLink.on){
          url = url.replace(/\?.*$/, "?"+deepLink.query);
          deepLink.on = false;
        };
        deepLink.url = root_url + url.replace(/\.json/, '');
        v = url.replace(/^.*\?/,'?');
        console.log("history.pushState:", v);
        history.pushState({}, "", v);
        return url;
      },
      ajaxError: null,
      ajaxObject: {
        dataType: 'json'
      },
      ajaxProcessing: function(data){
        if (data[0] == 0 ) {
          $.tablesorter.clearTableBody($('.tablesorter'))
        };
        $('#deepLink').val(deepLink.url);
        return data
      },
      // Set this option to false if your table data is preloaded into the table, but you are still using ajax
      processAjaxOnInit: true,
      output: '{startRow} to {endRow} of {totalRows} rows  (page {page}/{totalPages})',
      updateArrows: true,
      page: deepLink.page || 0,
      savePages: false,
      size: deepLink.per || 10,
      storageKey: 'tablesorter-pager',
      pageReset: 0,
      fixedHeight: false,
      removeRows: true,
      countChildRows: false,
      cssNext        : '.next',
      cssPrev        : '.prev',
      cssFirst       : '.first',
      cssLast        : '.last',
      cssGoto        : '.gotoPage',
      cssPageDisplay : '.pagedisplay',
      cssPageSize    : '.pagesize',
      cssDisabled    : 'disabled',
      cssErrorRow    : 'tablesorter-errorRow'
    };
  },

  asid: function(cell){
    return $(cell.parentElement).find('.asid').data("asid");
  },

  opnw: function(u,e){
    var nw = (e && (e.shiftKey || e.ctrlKey || e.altKey ));
    if (nw || !e) {
      window.open(u, "dbam_newWindow");
    } else {
      document.location.href=u;
    };
  }
}

$(function() {
  $('#placement_groups').multiSelect({
    cssClass: "ms-container-width-800",
    selectableHeader: "<div class='ms-custom-header'><strong>Available groups</strong></div><input type='text' class='search-input search-input-800' autocomplete='off' placeholder='Search...'>",
    selectionHeader: "<div class='ms-custom-header'><strong>Selected groups</strong></div><input type='text' class='search-input search-input-800' autocomplete='off' placeholder='Search...'>",
    afterInit: function(ms){
      var that = this,
              $selectableSearch = that.$selectableUl.prev(),
              $selectionSearch = that.$selectionUl.prev(),
              selectableSearchString = '#'+that.$container.attr('id')+' .ms-elem-selectable:not(.ms-selected)',
              selectionSearchString = '#'+that.$container.attr('id')+' .ms-elem-selection.ms-selected';

      that.qs1 = $selectableSearch.quicksearch(selectableSearchString)
              .on('keydown', function(e){
                if (e.which === 40){
                  that.$selectableUl.focus();
                  return false;
                }
              });

      that.qs2 = $selectionSearch.quicksearch(selectionSearchString)
              .on('keydown', function(e){
                if (e.which == 40){
                  that.$selectionUl.focus();
                  return false;
                }
              });
    },
    afterSelect: function(){
      this.qs1.cache();
      this.qs2.cache();
    },
    afterDeselect: function(){
      this.qs1.cache();
      this.qs2.cache();
    }
  });

  $('#deselect-all').click(function(){
    $('#placement_groups').multiSelect('deselect_all');
    return false;
  });
})
