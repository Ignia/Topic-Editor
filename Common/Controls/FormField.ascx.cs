/*==============================================================================================================================
| TEXT BOX FORM FIELD WRAPPER COMPONENT
|
| Author        Jeremy Caney, Ignia LLC (Jeremy@ignia.com)
| Client        Ignia, LLC
| Project       Library
|
| Purpose       This user control writes a cell, label, and input box.  It is meant to provide some level of centralization as
|               well as a template for customization.  It is not intended as a one-size-fits-all or global code base for form
|               fields; it is fully expected that this file will be modified on a per project or even per form basis.
|
>===============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               12.11.02        Jeremy Caney            Initial version template.
|               09.10.06        Jeremy Caney            Added built in support for email and phone validation.
|               09.10.06        Jeremy Caney            Added properties for customizing template.
|               07.14.07        Jeremy Caney            Added built in support for U.S. phone formatting.
|               12.28.07        Casey Margell           Added ValidationErrorMessage properties to support localizing
|               10.17.13        Jeremy Caney            Updated to use new AttributeTypeControl base class.
|               12.16.13        Jeremy Caney            Added support for default value to be set by the editor.
|               08.13.14        Katherine Trunkey       Added CSS classes 'form-control', 'input-sm' for Bootstrap support.
|               08.27.14        Katherine Trunkey       Updated overall control this.DataBind() to specific child control data
|                                                       binding.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| IMPORT NAMESPACES
\-----------------------------------------------------------------------------------------------------------------------------*/
  using System;
  using System.Web.UI;
  using System.Web.UI.WebControls;
  using System.Drawing;
  using Ignia.Topics;
  using Ignia.Topics.Web.Editor;

/*==============================================================================================================================
| CLASS: IGNIA FORM FIELD
\-----------------------------------------------------------------------------------------------------------------------------*/
[ Themeable(true) ]
  public partial class IgniaFormField : Ignia.Topics.Web.Editor.AttributeTypeControl {

  /*============================================================================================================================
  | DECLARE PUBLIC FIELDS
  >=============================================================================================================================
  | Public fields will be exposed as properties to user control
  \---------------------------------------------------------------------------------------------------------------------------*/
    public   string          LabelName           = "('LabelName' Not Defined)";

    public   int             MaxLength           = 500;
    public   int             FieldSize           = -1;
    public   int             FieldHeight         = -1;
    public   int             FieldFontSize       = 0;

    public   bool            Enabled             = true;

    public   TextBoxMode     TextMode            = TextBoxMode.SingleLine;

    public   string          CssClassRequired    = "Required";
    public   string          CssClassLabel       = "FormField Label";
    public   string          CssClassField       = "Field";

    public   string          OnKeyUp             = "";

    public   bool            ValidatePhone       = false;
    public   bool            ValidatePostal      = false;
    public   bool            ValidateEmail       = false;

    public   string          EmailErrorMessage   = "The email address you entered is not valid; please follow the email@host.domain format.";
    public   string          RangeErrorMessage   = "That value for %LabelName% must be between %MinimumValue% and %MaximumValue%.";
    public   string          PostalErrorMessage  = "The postal code you entered is not five digits.";
    public   string          PhoneErrorMessage   = "Your phone number must be in form: (XXX) XXX-XXXX";
    public   string          MaxLengthErrorMessage = "The field %LabelName% cannot be longer than %MaxLength%.";

    public   bool            FormatPhone         = false;

    public   string          MinimumValue        = null;
    public   string          MaximumValue        = null;
    public   string          CompareMethod       = "Integer";

    public   bool            Password            = false;

    public   string          ValidationGroup     = "";

  /*=========================================================================================================================
  | DECLARE PRIVATE VARIABLES
  >==========================================================================================================================
  | Declare variables that will have a page scope
  \------------------------------------------------------------------------------------------------------------------------*/
    private  int             intColumnSpan       = 1;
    private  string          _value              = null;
    private  bool            _isValueSet         = false;

    RequiredFieldValidator   objRequiredField    = new RequiredFieldValidator();

  /*===========================================================================================================================
  | PROPERTY: VALUE
  \--------------------------------------------------------------------------------------------------------------------------*/
    public override String Value {
      get {
        return Field.Text;
        }
      set {
        _value = null;
        if (value != null && Field != null) {
          Field.Text = value;
          _isValueSet = true;
          }
        else {
          _value = value;
          }
        }
      }

  /*===========================================================================================================================
  | PROPERTY: REQUIRED
  \--------------------------------------------------------------------------------------------------------------------------*/
    public override bool Required {
      get {
        return RequiredValidator.Enabled;
        }
      set {
        RequiredValidator.Enabled = value;
        if (value) {
          Field.CssClass = CssClassRequired;
          Field.Attributes.Add("required", "required");
          }
        else {
          Field.CssClass = CssClassField;
          }
        }
      }

  /*===========================================================================================================================
  | PROPERTY: FIELDOBJECT
  \--------------------------------------------------------------------------------------------------------------------------*/
    public TextBox FieldObject {
      get {
        return Field;
        }
      }

  /*=========================================================================================================================
  | PAGE INIT
  >==========================================================================================================================
  | Provide handling for functions that must run prior to page load.  This includes dynamically constructed controls.
  \------------------------------------------------------------------------------------------------------------------------*/
    void Page_Init(Object Src, EventArgs E) {

      Field.CssClass = "form-control input-sm FormField " + Field.CssClass;

    /*-------------------------------------------------------------------------------------------------------------------------
    | Set dynamic criteria for the input box based on input properties
    \------------------------------------------------------------------------------------------------------------------------*/
      Field.MaxLength = MaxLength;
      if (FieldFontSize > 0) Field.Font.Size = FieldFontSize;

    /*-------------------------------------------------------------------------------------------------------------------------
    | Setup Range Validator
    \------------------------------------------------------------------------------------------------------------------------*/
      if (MinimumValue != null && MaximumValue != null) {
        RangeValidator objValidator = new RangeValidator();
        objValidator.ID = "Range";
        objValidator.Text = "&nbsp;";
        objValidator.ControlToValidate = "Field";

        string error = RangeErrorMessage;
        error = RangeErrorMessage.Replace("%LabelName%", LabelName);
        error = RangeErrorMessage.Replace("%MinimumValue%", MinimumValue);
        error = RangeErrorMessage.Replace("%MaximumValue%", MaximumValue);

        objValidator.ErrorMessage = error;
        objValidator.MinimumValue = MinimumValue.ToString();
        objValidator.MaximumValue = MaximumValue.ToString();

        switch (CompareMethod.ToLower()) {
          case "string":   objValidator.Type = ValidationDataType.String;   break;
          case "integer":  objValidator.Type = ValidationDataType.Integer;  break;
          case "double":   objValidator.Type = ValidationDataType.Double;   break;
          case "date":     objValidator.Type = ValidationDataType.Date;     break;
          case "currency": objValidator.Type = ValidationDataType.Currency; break;
          }

        objValidator.ValidationGroup = ValidationGroup;
        PHRequired.Controls.Add(objValidator);
        }

    /*-------------------------------------------------------------------------------------------------------------------------
    | Setup Email Validator
    \------------------------------------------------------------------------------------------------------------------------*/
      if (ValidateEmail == true) {
        RegularExpressionValidator objValidator = new RegularExpressionValidator();
        objValidator.ID = "Postal";
        objValidator.Text = "&nbsp;";
        objValidator.ControlToValidate = "Field";
        objValidator.ErrorMessage = EmailErrorMessage;
        objValidator.ValidationExpression = @"^[^@]+@[^@]+\.[a-zA-Z]{1,4}$";
        objValidator.ValidationGroup = ValidationGroup;
        PHRequired.Controls.Add(objValidator);
        }

    /*-------------------------------------------------------------------------------------------------------------------------
    | Setup US Postal Validator
    \------------------------------------------------------------------------------------------------------------------------*/
      if (ValidatePostal == true) {
        RegularExpressionValidator objValidator = new RegularExpressionValidator();
        objValidator.ID = "Postal";
        objValidator.Text = "&nbsp;";
        objValidator.ControlToValidate = "Field";
        objValidator.ErrorMessage = PostalErrorMessage;
        objValidator.ValidationExpression = @"^\d{5}$";
        objValidator.ValidationGroup = ValidationGroup;
        PHRequired.Controls.Add(objValidator);
        }

    /*-------------------------------------------------------------------------------------------------------------------------
    | Setup US Phone Validator
    \------------------------------------------------------------------------------------------------------------------------*/
      if (ValidatePhone == true) {
        RegularExpressionValidator objValidator = new RegularExpressionValidator();
        objValidator.ID = "Phone";
        objValidator.Text = "&nbsp;";
        objValidator.ControlToValidate = "Field";
        objValidator.ErrorMessage = PhoneErrorMessage;
        objValidator.ValidationExpression = @"^(\([1-9][0-9]{2}\)\s)+[1-9][0-9]{2}-[0-9]{4}(\sx\s*[0-9]+)?$";
        objValidator.ValidationGroup = ValidationGroup;
        PHRequired.Controls.Add(objValidator);
        }

    /*-------------------------------------------------------------------------------------------------------------------------
    | Setup Max Length Validator
    \------------------------------------------------------------------------------------------------------------------------*/
      if (MaxLength > 0 && TextMode == TextBoxMode.MultiLine) {
        CustomValidator objValidator = new CustomValidator();
        objValidator.ID = "MaxLengthValidator";
        objValidator.Text = "&nbsp;";
        objValidator.ControlToValidate = "Field";

        string error = MaxLengthErrorMessage;
        error = error.Replace("%LabelName%", LabelName);
        error = error.Replace("%MaxLength%", MaxLength.ToString());

        objValidator.ErrorMessage = error;
        objValidator.ServerValidate += new ServerValidateEventHandler(this.CheckLength);
        objValidator.ValidationGroup = ValidationGroup;
        PHRequired.Controls.Add(objValidator);
        }

    /*-------------------------------------------------------------------------------------------------------------------------
    | Setup US Phone Formatter
    \------------------------------------------------------------------------------------------------------------------------*/
      if (FormatPhone) {
        if (!Page.ClientScript.IsStartupScriptRegistered("FormatPhone")) {
          Page.ClientScript.RegisterClientScriptInclude("FormatPhone", "/Common/Global/Client.Scripts/FormatPhone.js");
          }
        OnKeyUp += ";FormatPhone(this);";
        }

      }

  /*=========================================================================================================================
  | CUSTOM VALIDATOR: CHECK LENGTH
  >==========================================================================================================================
  | Checks the length of the field against the maximum length for the control.
  \------------------------------------------------------------------------------------------------------------------------*/
    public void CheckLength (object source, ServerValidateEventArgs args) {
      args.IsValid = (Field.Text.Length <= MaxLength);
      }

  /*=========================================================================================================================
  | PAGE LOAD
  >==========================================================================================================================
  | Handle all requests for page load, including state control based on user input
  \------------------------------------------------------------------------------------------------------------------------*/
    void Page_Load(Object Src, EventArgs E) {

    /*-----------------------------------------------------------------------------------------------------------------------
    | Handle deferred value set
    \----------------------------------------------------------------------------------------------------------------------*/
      if (_value != null) {
        Value = _value;
        }

    /*----------------------------------------------------------------------------------------------------------------------------
    | DATA BIND CHILD CONTROLS
    \---------------------------------------------------------------------------------------------------------------------------*/
      Field.DataBind();
      RequiredValidator.DataBind();

      }

  /*=========================================================================================================================
  | GET LABEL
  >==========================================================================================================================
  | Provide Label for Field Control
  \------------------------------------------------------------------------------------------------------------------------*/
    public String GetLabel() {
      return (this.ClientID + "_Label");
      }

  /*=========================================================================================================================
  | GET FIELD
  >==========================================================================================================================
  | Provide Field for Label Control
  \------------------------------------------------------------------------------------------------------------------------*/
    public String GetField() {
      return (this.ClientID + "_Field");
      }

  /*=========================================================================================================================
  | FORMATWIDTH
  >==========================================================================================================================
  | Provide stylesheet formatting for width
  \------------------------------------------------------------------------------------------------------------------------*/
    public String FormatWidth(int fieldSize, int fieldHeight) {
      string strDimensions = "";
      if (fieldSize >= 0) {
        strDimensions = strDimensions + "Width: " + fieldSize + "px;";
        }
      if (fieldHeight >= 0) {
        strDimensions = strDimensions + "Height: " + fieldHeight + "px;";
        }
      return strDimensions;
      }

    }