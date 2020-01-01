<%@ Control Language="C#" ClassName="Boolean" Inherits="Ignia.Topics.Web.Editor.AttributeTypeControl" %>

<%@ Import Namespace="Ignia.Topics" %>

<Script RunAt="Server">

/*==============================================================================================================================
| CHECKBOX FIELD
|
| Author        Jeremy Caney, Ignia LLC (Jeremy@ignia.com)
| Client        Ignia, LLC
| Project       Topics Editor
|
| Purpose       Implements a checkbox control for use within the Ignia Topics Editor.
|
>===============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               06.08.10        Jeremy Caney            Created initial version.
|               10.17.13        Jeremy Caney            Updated to use new AttributeTypeControl base class.
|               08.27.14        Katherine Trunkey       Updated overall control's this.DataBind() to specific data binding for
|                                                       child control.
|               09.13.14        Katherine Trunkey       Updated Field from checkbox to radio button selection.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| DECLARE PUBLIC FIELDS
>===============================================================================================================================
| Public fields will be exposed as properties to user control
\-----------------------------------------------------------------------------------------------------------------------------*/
  public        String          LabelName               = "";
  public        bool            Enabled                 = true;
  public        String          CssClassField           = "FormField Field";
  public        String          ValidationGroup         = "";

/*==============================================================================================================================
| DECLARE PRIVATE VARIABLES
>===============================================================================================================================
| Declare variables that will have a page scope
\-----------------------------------------------------------------------------------------------------------------------------*/
  private       string          _value                  = null;
  private       string          _inheritedValue         = "";
  private       bool            _isValueSet             = false;

/*==============================================================================================================================
| PROPERTY: INHERITED VALUE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override string InheritedValue {
    get {
      return _inheritedValue;
      }
    set {
      if (value != null) {
        _inheritedValue = (value.Equals("true", StringComparison.InvariantCultureIgnoreCase) || value.Equals("1")).ToString();
        }
      if (value != null && !_isValueSet) {
        Value = value;
        }
      }
    }

/*==============================================================================================================================
| PROPERTY: VALUE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override String Value {
    get {
      string value = "0";
      if (Field.SelectedItem != null) {
        value = Field.SelectedItem.Value;
        }
      return value;
      }
    set {
      _value = null;
      if (value != null && Field != null) {
        if (value.Equals("true", StringComparison.InvariantCultureIgnoreCase) || value.Equals("1")) {
          Field.SelectedValue = "1";
          }
        else {
          Field.SelectedValue = "0";
          }
        _isValueSet = true;
        }
      else {
        _value = value;
        }
      }
    }

/*==============================================================================================================================
| PROPERTY: FIELD OBJECT
\-----------------------------------------------------------------------------------------------------------------------------*/
  public RadioButtonList FieldObject {
    get {
      return Field;
      }
    }

/*==============================================================================================================================
| PAGE LOAD
>===============================================================================================================================
| Handle all requests for page load, including state control based on user input
\-----------------------------------------------------------------------------------------------------------------------------*/
  void Page_Load(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | CSS CLASS
  \---------------------------------------------------------------------------------------------------------------------------*/
    Field.CssClass              = "FormField " + Field.CssClass;

  /*----------------------------------------------------------------------------------------------------------------------------
  | HANDLE DEFERRED VALUE SET
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (_value != null) {
      Value                     = _value;
      }
    if (!String.IsNullOrEmpty(Value) && (Value.Equals("0") || Value.Equals("1"))) {
      Field.SelectedValue       = Value;
      }

  /*-------------------------------------------------------------------------------------------------------------------------
  | BIND CHILD CONTROLS
  \------------------------------------------------------------------------------------------------------------------------*/
    Field.DataBind();

    }

</Script>

<asp:RadioButtonList
  ID                    = "Field"
  RepeatLayout          = "UnorderedList"
  CssClass              = "Radio-Buttons"
  Enabled               = "<%# Enabled %>"
  RunAt                 = "Server"
  >
  <asp:ListItem Value="1" Text="Yes" />
  <asp:ListItem Value="0" Text="No" />
</asp:RadioButtonList>