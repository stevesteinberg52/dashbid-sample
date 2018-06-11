App = this.App || {};

App.admin_margin_report = {
  setup: function() {
    this.sharedBehaviour();
  },

  sharedBehaviour: function() {
  },

  filter_form: function() {
    $('#date_range').on('change',function() {
      if (this.value == 'custom') {
      }
      else if (this.value == 'thismonth') {
        $('#start_date').val(moment().subtract('days', 1).startOf('month').format('YYYY-MM-DD'));
        $('#end_date').val(moment().subtract('days', 1).format('YYYY-MM-DD'));
      }
      else if (this.value == 'lastmonth') {
        $('#start_date').val(moment().subtract('days', 1).subtract('month', 1).startOf('month').format('YYYY-MM-DD'));
        $('#end_date').val(moment().subtract('days', 1).subtract('month', 1).endOf('month').format('YYYY-MM-DD'));
      }
      else if (this.value == 'yesterday') {
        $('#start_date').val(moment().subtract('day', 1).format('YYYY-MM-DD'));
        $('#end_date').val(moment().subtract('day', 1).format('YYYY-MM-DD'));
      }
    });

    $('#start_date').on('change',function() {
      $('#date_range').val('custom');
    });
    $('#end_date').on('change',function() {
      $('#date_range').val('custom');
    });

    $("#customer_id").chosen();
    $("#network_id").chosen();
    $("#adops_assignee_id").chosen();
    $("#account_contact_id").chosen();
    $("#team").chosen();
    $("#dbam_symbol").chosen();
    $("#group_id").chosen();
  },

  data_table: function() {
    $("#margin-report thead th").data("sorter", false);

    $("#margin-report").tablesorter({
      widgets: ['stickyHeaders'],
      headers : { 0 : { sorter: false } }
    });
  }
}