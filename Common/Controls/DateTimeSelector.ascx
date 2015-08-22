<%@ Control Language="C#" ClassName="DateTimeSelector" Inherits="Ignia.Topics.Editor.AttributeTypeControl" %>

<%@ Import Namespace="Ignia.Topics" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>

<Script RunAt="Server">

/*==============================================================================================================================
| DATE AND/OR TIME SELECTOR (PICKER)
|
| Author        Katherine Trunkey, Ignia LLC (Katherine.Trunkey@ignia.com)
| Client        Ignia
| Project       Topics Editor
|
| Purpose       Provide a date picker along with a time selection, if enabled, in order to populate a simple text input field.
|               Uses the jQuery UI Datepicker widget with Trent Richardson's Timepicker add-on.
|
| References    https://jqueryui.com/datepicker/
|               https://api.jqueryui.com/datepicker/
|               http://trentrichardson.com/examples/timepicker/
|
| Known Issues  Non-breaking, compatibility error "Error parsing the date/time string: Unknown name at position 0"
|               https://github.com/trentrichardson/jQuery-Timepicker-Addon/issues/643
|
>===============================================================================================================================
| Revisions     Date            Author                          Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               06.08.15        Katherine Trunkey               Created initial version.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| PUBLIC MEMBERS
\-----------------------------------------------------------------------------------------------------------------------------*/
  public        bool            IncludeDatePicker               = true;
  public        bool            IncludeTimePicker               = false;
  public        string          DateFormat                      = "mm/dd/yy";   // Uses jQuery UI DatePicker date format
  public        string          TimeFormat                      = "hh:mm TT";    // Uses TR's Date/Time Picker time format
  public        string          DateTimeSeparator               = " ";
  public        string          DateTimeOffset                  = "0";
  public        string          DateTimeOffsetDirection         = "Future";
  public        string          DateTimeOffsetUnits             = "Days";

/*==============================================================================================================================
| PRIVATE FIELDS
\-----------------------------------------------------------------------------------------------------------------------------*/
  private       bool            _isDataBound                    = false;
  private       string          _defaultDate                    = null;
  private       string          _defaultTime                    = null;
  private       string          _value                          = null;
  private       bool            _isValueSet                     = false;

/*==============================================================================================================================
| VALUE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override string Value {
    get {
      return DateSelection.Text + ((!String.IsNullOrEmpty(TimeSelection.Text))? " " + TimeSelection.Text : "");
    }
    set {
      _value = null;
      if (value != null && (DateSelection != null || TimeSelection != null)) {
        DateTime dateTimeValue;
        if (DateTime.TryParse(value, out dateTimeValue)) {
          DateSelection.Text    = dateTimeValue.ToString("MM/dd/yyyy");
          TimeSelection.Text    = dateTimeValue.ToString(TimeFormat);
        }
        _isValueSet = true;
      }
      else {
        _value = value;
      }
    }
  }

/*==============================================================================================================================
| DEFAULT DATE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string DefaultDate {
    get {
      if (String.IsNullOrEmpty(_defaultDate)) {
        if (!String.IsNullOrEmpty(Value)) {
          DateTime dateValue;
          if (DateTime.TryParse(Value, out dateValue)) {
            _defaultDate        = dateValue.ToString("MM/dd/yyyy");
          }
        }
        else {
        /*----------------------------------------------------------------------------------------------------------------------
        | PERFORM .NET TO JAVASCRIPT DATE FORMAT TRANSLATIONS
        \---------------------------------------------------------------------------------------------------------------------*/



          _defaultDate          = DateTime.Now.ToString("MM/dd/yyyy");
        }

      }
      return _defaultDate;
    }
    set {
      _defaultDate = value;
    }
  }

/*==============================================================================================================================
| DEFAULT TIME
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string DefaultTime {
    get {
      if (String.IsNullOrEmpty(_defaultTime)) {
        if (!String.IsNullOrEmpty(Value)) {
          DateTime timeValue;
          if (DateTime.TryParse(Value, out timeValue)) {
            _defaultTime        = timeValue.ToString(TimeFormat);
          }
        }
        else {
          _defaultTime          = DateTime.Now.ToString(TimeFormat);
        }

      }
      return _defaultTime;
    }
    set {
      _defaultTime = value;
    }
  }

/*==============================================================================================================================
| PAGE INIT
\-----------------------------------------------------------------------------------------------------------------------------*/
  protected void Page_Init(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | BIND CONTROL
  \---------------------------------------------------------------------------------------------------------------------------*/
    this.DataBind();

  }

/*==============================================================================================================================
| PAGE LOAD
\-----------------------------------------------------------------------------------------------------------------------------*/
  protected void Page_Load(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | REGISTER JQUERY UI PLUGIN, JQUERY UI TIMEPICKER PLUGIN, AND INITIALIZATION SCRIPTS
  \---------------------------------------------------------------------------------------------------------------------------*/
    ClientScriptManager         clientScript                    = Page.ClientScript;
    Type                        clientScriptType                = this.GetType();
    string                      jQueryUIScriptName              = "jQueryUI";
    string                      jQueryUITimepickerScriptName    = "jQueryUITimepicker";

  //Register jQuery UI
    if (!clientScript.IsClientScriptIncludeRegistered(clientScriptType, jQueryUIScriptName)) {
      clientScript.RegisterClientScriptInclude(clientScriptType, jQueryUIScriptName, ResolveClientUrl("/!Admin/Topics/Common/Scripts/Vendor/jQueryUI/jQuery-ui.min.js"));
    }
  //Register Trent Richardson's jQuery UI Timepicker add-on
    if (!clientScript.IsClientScriptIncludeRegistered(clientScriptType, jQueryUITimepickerScriptName)) {
      clientScript.RegisterClientScriptInclude(clientScriptType, jQueryUITimepickerScriptName, ResolveClientUrl("/!Admin/Topics/Common/Scripts/Vendor/TrentRichardson/jquery-ui-timepicker-addon.js"));
    }

  /*----------------------------------------------------------------------------------------------------------------------------
  | REGISTER CSS DEPENDENCIES
  \---------------------------------------------------------------------------------------------------------------------------*/
  //Register jQuery UI CSS
    this.Page.Header.Controls.Add(
      new System.Web.UI.LiteralControl("<link rel=\"stylesheet\" type=\"text/css\" href=\"" + ResolveUrl("/!Admin/Topics/Common/Styles/Vendor/jQueryUI/jquery-ui.min.css") + "\" />")
    );
  //Register Trent Richardson's jQuery UI Timepicker add-on CSS
    this.Page.Header.Controls.Add(
      new System.Web.UI.LiteralControl("<link rel=\"stylesheet\" type=\"text/css\" href=\"" + ResolveUrl("/!Admin/Topics/Common/Styles/Vendor/TrentRichardson/jquery-ui-timepicker-addon.min.css") + "\" />")
    );

  /*----------------------------------------------------------------------------------------------------------------------------
  | DATA BIND CONTROL
  \---------------------------------------------------------------------------------------------------------------------------*/
    this.DataBind();

  /*----------------------------------------------------------------------------------------------------------------------------
  | SET DEFAULT OR RETURNED FIELD VALUES
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (IncludeDatePicker) {
      DateSelection.Text        = DefaultDate;
    }
    if (IncludeTimePicker) {
      TimeSelection.Text        = DefaultTime;
    }

  /*----------------------------------------------------------------------------------------------------------------------------
  | SET FIELDS' CSS CLASS DEPENDING ON REQUESTED FIELDS
  \---------------------------------------------------------------------------------------------------------------------------*/
    string      cssClass        = "form-control input-sm";

  //If both fields are included, add 'combined' class
    if (IncludeDatePicker && IncludeTimePicker) {
      DateSelection.CssClass    = TimeSelection.CssClass        = cssClass      + " combined";
    }
  //Otherwise, add 'single' class
    else if (IncludeDatePicker) {
      DateSelection.CssClass    = cssClass                      + " single";
    }
    else {
      TimeSelection.CssClass    = cssClass                      + " single";
    }

  }

</Script>

<!-- TEMPORARY!!! -->
<style type="text/css">
  input.combined {
    display: inline-block;
    width: 49% !important;
  }
  input[id$="DateSelection"].combined { float: left; }
  input[id$="TimeSelection"].combined { float: right; }
  .fields.datetime { min-height: 33px; }
</style>

<div style="padding: 10px; border: 1px dotted red; display: none;">
  <p>DefaultDate: <%# DefaultDate %></p>
  <p>DefaultTime: <%# DefaultTime %></p>
  <p>Value: <%# Value %></p>
</div>
<div class="datetime fields">

  <asp:PlaceHolder Visible=<%# IncludeDatePicker %> RunAt="Server">
    <asp:TextBox ID="DateSelection" name="DateSelection" RunAt="Server" />
  </asp:PlaceHolder>
  <asp:PlaceHolder Visible=<%# IncludeTimePicker %> RunAt="Server">
    <asp:TextBox ID="TimeSelection" name="TimeSelection" RunAt="Server" />
  </asp:PlaceHolder>

</div>

<script>
  $(function() {

  //Instantiate date and/or time picker
  <asp:PlaceHolder Visible=<%# IncludeDatePicker && IncludeTimePicker %> RunAt="Server">
    $('#<%# DateSelection.ClientID %>')
      .datetimepicker(
        {
          dateFormat    : '<%# DateFormat %>',
          altTimeFormat : '<%# TimeFormat %>',
          separator             : '<%# DateTimeSeparator %>',
          pickerTimeFormat : '<%# TimeFormat %>',
        //defaultDate   : '<%# DefaultDate %>',
        //defaultValue  : '<%# DefaultTime %>',
        //altFieldTimeOnly      : true,
          altField      : '#<%# TimeSelection.ClientID %>'
        }
      );
    $('#<%# DateSelection.ClientID %>').on('change', function(e) {

      var dateSelection = $('input[id$="DateSelection"]');
      var timeSelection = $('input[id$="TimeSelection"]');

      console.log($(dateSelection).attr('id'));
      console.log($('#' + $(dateSelection).attr('id')).val());

      console.log('Value: <%= Value %>');

    });
  </asp:PlaceHolder>
  <asp:PlaceHolder Visible=<%# IncludeDatePicker && !IncludeTimePicker %> RunAt="Server">
    $('#<%# DateSelection.ClientID %>')
      .datepicker(
        {
          dateFormat    : '<%# DateFormat %>',
          defaultDate   : +7
        }
      );
  </asp:PlaceHolder>
  <asp:PlaceHolder Visible=<%# !IncludeDatePicker && IncludeTimePicker %> RunAt="Server">
    $('#<%# TimeSelection.ClientID %>')
      .timepicker(
        {
          timeFormat    : '<%# TimeFormat %>'
        }
      );

  </asp:PlaceHolder>

  });
</script>