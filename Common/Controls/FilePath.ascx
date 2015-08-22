<%@ Control Language="C#" ClassName="Boolean" Inherits="Ignia.Topics.Editor.AttributeTypeControl" %>

<%@ Import Namespace="Ignia.Topics" %>
<%@ Import Namespace="Ignia.Topics.Editor" %>
<%@ Import Namespace="System.Linq" %>

<Script RunAt="Server">

/*=============================================================================================================================
| FILE PATH FIELD
|
| Author        Jeremy Caney, Ignia LLC (Jeremy@ignia.com)
| Client        Ignia, LLC
| Project       Topics Editor
|
| Purpose       Implements a textbox specifically intended to evaluate file paths. Includes support for inheritance, relative
|               paths, format validation, and previewing of links.
|
>==============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               10.03.14        Jeremy Caney            Created initial version.
\----------------------------------------------------------------------------------------------------------------------------*/

/*=============================================================================================================================
| DECLARE PUBLIC FIELDS
>==============================================================================================================================
| Public fields will be exposed as properties to user control
\----------------------------------------------------------------------------------------------------------------------------*/
  public        String          LabelName               = "";
  public        bool            Enabled                 = true;
  public        String          CssClassField           = "FormField Field";
  public        String          ValidationGroup         = "";

/*=============================================================================================================================
| DECLARE PRIVATE VARIABLES
>==============================================================================================================================
| Declare variables that will have a page scope
\----------------------------------------------------------------------------------------------------------------------------*/
  private       string          _value                  = null;
  private       bool            _isValueSet             = false;
  private       string          _truncatePathAtTopic    = "";
  private       bool            _inheritValue           = true;
  private       bool            _relativeToParent       = true;
  private       string          _inheritedValue         = "";
  private       bool            _includeLeafTopic       = true;

/*=============================================================================================================================
| PROPERTY: VALUE
\----------------------------------------------------------------------------------------------------------------------------*/
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

/*==============================================================================================================================
| PROPERTY: TRUNCATE PATH AT TOPIC
>-------------------------------------------------------------------------------------------------------------------------------
| Determines the Topic level (based on Topic.Key) at which to stop recursive processing logic for InheritedValue. If set, the
| InheritedValue will ignore Topics under the specified Topic when formulating the full file path based on InheritedValue.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string TruncatePathAtTopic {
    get {
      return _truncatePathAtTopic;
      }
    set {
      _truncatePathAtTopic = value;
      }
    }

/*==============================================================================================================================
| PROPERTY: INCLUDE LEAF TOPIC
>-------------------------------------------------------------------------------------------------------------------------------
| Determines whether the current leaf Topic should be included in the resulting inherited file path.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool IncludeLeafTopic {
    get {
      return _includeLeafTopic;
      }
    set {
      _includeLeafTopic = value;
      }
    }

/*==============================================================================================================================
| PROPERTY: INHERIT VALUE
>-------------------------------------------------------------------------------------------------------------------------------
| Determines whether the value is expected to be inherited from parent topics if left blank.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool InheritValue {
    get {
      return _inheritValue;
      }
    set {
      _inheritValue = value;
      }
    }

/*=============================================================================================================================
| PROPERTY: RELATIVE TO PARENT
>------------------------------------------------------------------------------------------------------------------------------
| Determines whether the value should automatically inject any parent topics in the path. If set, the value will be set to the
| inherited value (if present) alongside the path between the level at which that value is set and the current topic.
\----------------------------------------------------------------------------------------------------------------------------*/
  public bool RelativeToParent {
    get {
      return _relativeToParent;
      }
    set {
      _relativeToParent = value;
      }
    }

/*==============================================================================================================================
| PROPERTY: INHERITED VALUE
>-------------------------------------------------------------------------------------------------------------------------------
| Overrides default InheritedValue implementation by crawling up the tree to identify the source of inheritance (if available)
| and sets the value based on the base path defined by the parent (assuming InheritValue) and the relative path between that
| topic and the current topic (assuming RelativeToParent).
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override string InheritedValue {
    get {

      if (String.IsNullOrEmpty(_inheritedValue)) {
        Topic           topic                   = ((TopicPage)Page).Topic;
        string[]        topicsToTruncate        = null;
        if (!String.IsNullOrEmpty(TruncatePathAtTopic)) {
          topicsToTruncate                      = TruncatePathAtTopic.Split(',').ToArray();
          }
        if (InheritValue && RelativeToParent) {
          _inheritedValue                       = FilePath.GetPath(topic, Attribute.Key, IncludeLeafTopic, topicsToTruncate);
          }
        else if (InheritValue) {
          _inheritedValue                       = topic.GetAttribute(Attribute.Key, true);
          }
        else {
          _inheritedValue                       = "";
          }
        }

      return _inheritedValue;

      }

    set {
    //do nothing; value will be set by getter
      }
    }

/*=============================================================================================================================
| PROPERTY: FIELD OBJECT
\----------------------------------------------------------------------------------------------------------------------------*/
  public TextBox FieldObject {
    get {
      return Field;
      }
    }

/*=============================================================================================================================
| PAGE LOAD
\----------------------------------------------------------------------------------------------------------------------------*/
  void Page_Load(Object Src, EventArgs E) {

  /*---------------------------------------------------------------------------------------------------------------------------
  | DATA BIND CONTROL
  \--------------------------------------------------------------------------------------------------------------------------*/
    this.DataBind();

  /*---------------------------------------------------------------------------------------------------------------------------
  | HANDLE DEFERRED VALUE SET
  \--------------------------------------------------------------------------------------------------------------------------*/
    if (_value != null) {
      Value                                     = _value;
      }

  /*---------------------------------------------------------------------------------------------------------------------------
  | BIND CHILD CONTROLS
  \--------------------------------------------------------------------------------------------------------------------------*/
    Field.DataBind();

    }

</Script>

<asp:TextBox
  ID                    = "Field"
  Enabled               = <%# Enabled %>
  placeholder           = <%# InheritedValue %>
  CssClass              = <%# "form-control input-sm " + CssClassField %>
  RunAt                 = "Server"
  />

<asp:RegularExpressionValidator
  ID                    = "FilePathValidator"
  ControlToValidate     = "Field"
  ValidationExpression  = "^([A-Za-z]+:)?(\/{0,2}|\\{0,2})(?:[0-9a-zA-Z _\-\.]+(\/|\\?))+$"
  ErrorMessage          = "The image path specified is not a valid file path."
  Display               = "None"
  RunAt                 = "Server"
  />