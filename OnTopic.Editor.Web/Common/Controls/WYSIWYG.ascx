<%@ Control Language="C#" ClassName="Wysiwyg" Inherits="OnTopic.Web.Editor.AttributeTypeControl" %>

<%@ Import Namespace="OnTopic" %>

<Script RunAt="Server">

/*==============================================================================================================================
| WYSIWYG FIELD
|
| Author        Jeremy Caney, Ignia LLC (Jeremy@ignia.com)
| Client        Ignia
| Project       Topics Library
|
| Purpose       Implements the CKEditor control as a plugin for the Ignia OnTopic CMS.
|
>===============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               06.08.10        Jeremy Caney            Created initial version.
|               10.17.13        Jeremy Caney            Updated to use new AttributeTypeControl base class.
|               08.27.14        Katherine Trunkey       Updated 'Field' and 'RequiredValidator' controls to be specifically
|                                                       data bound rather than calling an additional this.DataBind() for
|                                                       the control.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| DECLARE PUBLIC FIELDS
>===============================================================================================================================
| Public fields will be exposed as properties to user control
\-----------------------------------------------------------------------------------------------------------------------------*/
  public        String          LabelName               = "";
  public        bool            Enabled                 = true;

  public        int             Columns                 = 70;
  public        int             Rows                    = 30;

  public        String          CssClassRequired        = "Required";
  public        String          CssClassField           = "FormField Field";

  public        String          ValidationGroup         = "";

/*==============================================================================================================================
| DECLARE PRIVATE VARIABLES
>===============================================================================================================================
| Declare variables that will have a page scope
\-----------------------------------------------------------------------------------------------------------------------------*/
  private       int             _height                 = 0;

/*==============================================================================================================================
| PROPERTY: VALUE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override String Value {
    get {
      return Field.Text.Replace("<p>&nbsp;</p>", "").Replace("<p>&amp;nbsp;</p>", "").Replace("<p></p>", "").Replace("\r\n", "");
      }
    set {
      Field.Text = value;
      }
    }

/*==============================================================================================================================
| PROPERTY: REQUIRED
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override bool Required {
    get {
      return RequiredValidator.Enabled;
      }
    set {
      RequiredValidator.Enabled = value;
      if (value) {
        Field.CssClass = CssClassRequired;
        }
      else {
        Field.CssClass = CssClassField;
        }
      }
    }

/*==============================================================================================================================
| PROPERTY: FIELD OBJECT
\-----------------------------------------------------------------------------------------------------------------------------*/
  public TextBox FieldObject {
    get {
      return Field;
      }
    }

/*==============================================================================================================================
| PROPERTY: HEIGHT
|-------------------------------------------------------------------------------------------------------------------------------
| Provides a settable reference to the height in pixels to be used for the CKEditor WYSIWYG configuration. If Height is not set
| (or is set to 0), uses Rows*20 for value.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public int Height {
    get {
      if (_height == 0) {
        _height = Rows*20;
        }
      return _height;
      }
    set {
      _height = value;
      }
    }

/*==============================================================================================================================
| PAGE LOAD
>===============================================================================================================================
| Handle all requests for page load, including state control based on user input
\-----------------------------------------------------------------------------------------------------------------------------*/
  void Page_Load(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | ENSURE INCLUSION OF CLIENT SCRIPT
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (!Page.ClientScript.IsClientScriptIncludeRegistered("CKEditor")) {
      Page.ClientScript.RegisterClientScriptInclude("CKEditor", "Common/Scripts/CKEditor/CKEditor.js");
      }

  /*----------------------------------------------------------------------------------------------------------------------------
  | SET CSS CLASS
  \---------------------------------------------------------------------------------------------------------------------------*/
    Field.CssClass      = "FormField " + Field.CssClass;

  /*----------------------------------------------------------------------------------------------------------------------------
  | DATA BIND CHILD CONTROLS
  \---------------------------------------------------------------------------------------------------------------------------*/
    Field.DataBind();
    RequiredValidator.DataBind();

    }

</Script>
<style type="text/css">
  .Content div.x-tab-panel {
    margin-top: 30px;
    }
  .Content ul.x-tab-strip {
    list-style-image: none;
    padding-left: 0px;
    }
</style>

<asp:TextBox
  ID                    = "Field"
  TextMode              = "Multiline"
  Columns               = <%# Columns %>
  Rows                  = <%# Rows %>
  Enabled               = <%# Enabled %>
  RunAt                 = "Server"
  />

<div style="display: none;"><%= Field.UniqueID %></div>

<asp:RequiredFieldValidator
  ID                    = "RequiredValidator"
  ControlToValidate     = "Field"
  ValidationGroup       = <%# ValidationGroup %>
  Enabled               = "False"
  RunAt                 = "Server"
  />

<script type="text/javascript">
  (function($) {

    var textareaId      = '<%= Field.ClientID %>';

    $('[id*="EditorModal"]').on('shown.bs.modal', function(e) {
      $('.Modal [id*="<%= Field.ClientID %>"]').attr('id', '<%= Field.ClientID %>_Modal');
      console.log('new id: ' + $('[id*="<%= Field.ClientID %>"]').attr('id'));
      textareaId         = '<%= Field.ClientID %>_Modal';
      setEditorInstance(textareaId);
      console.log(textareaId);
      return;
      });

    setEditorInstance(textareaId);

    })(jQuery);

  function setEditorInstance(textareaId) {
  //console.log(textareaId + ' on setEditorInstance');
    CKEDITOR.replace(textareaId, {
      height            : '<%= Height %>',
      resize_maxHeight  : '<%= (Height + 300) %>',
      customConfig      : 'customConfig.js'
      });
    }
</script>