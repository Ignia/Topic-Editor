<%@ Control Language="C#" ClassName="TokenizedTopicList" Inherits="OnTopic.Web.Editor.AttributeTypeControl" %>

<%@ Import Namespace="OnTopic" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>
<%@ Import Namespace="System.Collections.ObjectModel" %>

<Script RunAt="Server">

/*==============================================================================================================================
| TOKENIZED TOPIC LIST
|
| Author:       Katherine Trunkey, Ignia LLC (Katherine.Trunkey@ignia.com)
| Client        Ignia
| Project       Topics Editor
|
| Purpose:      Provide a tokenized, search-ahead selection box for Topics in order to associate selected Topics with the
|               current (Page) Topic. May be used as a category/related Topics selector (e.g., for "Related Topics") or by the
|               Topic Pointer wrapper control.
|
>===============================================================================================================================
| Revisions     Date            Author                          Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               03.28.15        Katherine Trunkey               Created initial version.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| PUBLIC MEMBERS
\-----------------------------------------------------------------------------------------------------------------------------*/
  public        bool            IsAutoPostback                  = false;

/*==============================================================================================================================
| PRIVATE FIELDS
\-----------------------------------------------------------------------------------------------------------------------------*/
  private       bool            _isDataBound                    = false;
  private       string          _value                          = null;
  private       bool            _isValueSet                     = false;
  private       string          _scope                          = null;
  private       string          _attributeName                  = null;
  private       string          _attributeValue                 = null;
  private       string          _resultLimit                    = null;
  private       string          _tokenLimit                     = null;
  private       string          _searchProperty                 = null;
  private       string          _queryParameter                 = null;
  private       bool            _asRelationship                 = false;

/*==============================================================================================================================
| SCOPE
>-------------------------------------------------------------------------------------------------------------------------------
| Settable reference to the Topic scope (e.g., "Web") by which to filter the selectable token list.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string Scope {
    get {
      return _scope;
    }
    set {
      _scope = value;
    }
  }

/*==============================================================================================================================
| ATTRIBUTE NAME
>-------------------------------------------------------------------------------------------------------------------------------
| Settable reference to the Attribute Name (e.g., "ContentType") by which to filter the selectable token list. Both
| AttributeName and AttributeValue are required for use.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string AttributeName {
    get {
      return _attributeName;
    }
    set {
      _attributeName = value;
    }
  }

/*==============================================================================================================================
| ATTRIBUTE VALUE
>-------------------------------------------------------------------------------------------------------------------------------
| Settable reference to the Attribute Value (e.g., "Page") by which to filter the selectable token list. Both AttributeName and
| AttributeValue are required for use.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string AttributeValue {
    get {
      return _attributeValue;
    }
    set {
      _attributeValue = value;
    }
  }

/*==============================================================================================================================
| RESULT LIMIT
>-------------------------------------------------------------------------------------------------------------------------------
| Settable reference for the maximum number of Topic results to pull from Topics.Json.aspx.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string ResultLimit {
    get {
      return _resultLimit;
    }
    set {
      _resultLimit = value;
    }
  }

/*==============================================================================================================================
| TOKEN LIMIT
>-------------------------------------------------------------------------------------------------------------------------------
| Settable reference for the maximum number of tokens allowed to be selected by the user. Maps to Tokeninput's 'tokenLimit'
| setting.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string TokenLimit {
    get {
      return _tokenLimit;
    }
    set {
      _tokenLimit = value;
    }
  }

/*==============================================================================================================================
| AS RELATIONSHIP
>-------------------------------------------------------------------------------------------------------------------------------
| Determines whether to utilize the control as a replacement for (or equivalent of) Relationships.ascx.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool AsRelationship {
    get {
      return _asRelationship;
    }
    set {
      _asRelationship = value;
    }
  }

/*==============================================================================================================================
| SEARCH PROPERTY
>-------------------------------------------------------------------------------------------------------------------------------
| Determines what property in a Topic's JSON object to search against (corresponds to Token-Input's propertyToSearch setting).
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string SearchProperty {
    get {
      if (_searchProperty == null) {
        _searchProperty = "key";
      }
      return _searchProperty;
    }
    set {
      _searchProperty = value;
    }
  }

/*==============================================================================================================================
| QUERY PARAMETER
>-------------------------------------------------------------------------------------------------------------------------------
| Determines the JSON querystring parameter expected to contain the search term on the server-side (corresponds to Token-
| Token-Input's queryParam setting); defaults to AttributeValue.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string QueryParameter {
    get {
      if (_queryParameter == null) {
        _queryParameter = "AttributeValue";
      }
      return _queryParameter;
    }
    set {
      _queryParameter = value;
    }
  }

/*==============================================================================================================================
| VALUE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override String Value {
    get {
      return TokenizedTopicSelection.Text;
    }
    set {
      _value = null;
      if (value != null && TokenizedTopicSelection != null) {
        TokenizedTopicSelection.Text = value;
        _isValueSet = true;
      }
      else {
        _value = value;
      }
    }
  }

/*==============================================================================================================================
| SELECTED TOPICS
>-------------------------------------------------------------------------------------------------------------------------------
| If Value is available, returns a JSON string based on the selected Topic(s) for use with TokenInput's prePopulate setting.
\-----------------------------------------------------------------------------------------------------------------------------*/
  private string SelectedTopics {
    get {
      string    selectedTopics  = "[";

    /*--------------------------------------------------------------------------------------------------------------------------
    | SPLIT VALUE INTO TOPIC IDS; GET JSON INFORMATION FOR EACH TOPIC ID
    \-------------------------------------------------------------------------------------------------------------------------*/
      if (!String.IsNullOrEmpty(Value)) {
        string[] topicValues    = Value.Split(',').ToArray();
        foreach (string topicId in topicValues) {
          selectedTopics       += GetTopicJson(topicId);
        }
      }

      selectedTopics           += "]";
      selectedTopics            = selectedTopics.Replace(",]", "]");

      return selectedTopics;
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
  | REGISTER TOKEN-INPUT PLUGIN AND TOKENIZED TOPIC LIST SCRIPTS
  \---------------------------------------------------------------------------------------------------------------------------*/
    ClientScriptManager         clientScript                    = Page.ClientScript;
    Type                        clientScriptType                = this.GetType();
    string                      tokenInputScriptName            = "TokenInputScript";
    string                      tokenizedTopicListScriptName    = "TokenizedTopicListScript";

    if (!clientScript.IsClientScriptIncludeRegistered(clientScriptType, tokenInputScriptName)) {
      clientScript.RegisterClientScriptInclude(clientScriptType, tokenInputScriptName, ResolveClientUrl("/!Admin/Topics/Common/Scripts/Vendor/TokenInput/jquery.tokeninput.js"));
    }
    if (!clientScript.IsClientScriptIncludeRegistered(clientScriptType, tokenizedTopicListScriptName)) {
      clientScript.RegisterClientScriptInclude(clientScriptType, tokenizedTopicListScriptName, ResolveClientUrl("/!Admin/Topics/Common/Scripts/TokenizedTopicList.js"));
    }

  }

/*==============================================================================================================================
| GET TOPIC JSON
>===============================================================================================================================
| Returns a JSON object (e.g., { "id": "123", "key": "Key", ... }) for use with TokenInput's prePopulate setting, given the
| provided Topic ID.
\-----------------------------------------------------------------------------------------------------------------------------*/
  private string GetTopicJson(string topicId) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | INTERNAL VARIABLES
  \---------------------------------------------------------------------------------------------------------------------------*/
    string      topicJson       = "";
    Topic       topic           = TopicRepository.DataProvider.Load(Int32.Parse(topicId));

  /*----------------------------------------------------------------------------------------------------------------------------
  | WRITE OUT JSON OBJECT FOR TOPIC IF TOPIC IS AVAILABLE
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (topic != null) {

      topicJson                += "{"
        + "\"id\":\""           + topic.Id                                                      + "\", "
        + "\"key\":\""          + HttpUtility.HtmlAttributeEncode(topic.Key)                    + "\", "
        + "\"text\":\""         + HttpUtility.HtmlAttributeEncode(topic.Title)                  + "\", "
        + "\"path\":\""         + HttpUtility.HtmlAttributeEncode(topic.GetUniqueKey())              + "\", "
        + "\"webPath\":\""      + HttpUtility.HtmlAttributeEncode(topic.GetWebPath())                + "\""
        + "},";

    }

  /*----------------------------------------------------------------------------------------------------------------------------
  | RETURN TOPIC JSON
  \---------------------------------------------------------------------------------------------------------------------------*/
    return topicJson;

  }

</Script>

<div><asp:TextBox ID="TokenizedTopicSelection" name="TokenizedTopicSelection" CssClass="form-control input-sm" Text=<%# Value %> RunAt="Server" /></div>

<script>
  $(function() {

  //Create new instance of TokenizedTopics and set relevant properties
    var tokenizedTopics                 = new TokenizedTopics();
    tokenizedTopics.selector            = '#<%= TokenizedTopicSelection.ClientID %>';
    tokenizedTopics.scope               = '<%# Scope?? "" %>';
    tokenizedTopics.attributeName       = '<%# AttributeName?? "" %>';
    tokenizedTopics.attributeValue      = '<%# AttributeValue?? "" %>';
    tokenizedTopics.searchProperty      = '<%# SearchProperty.ToLower() %>';
    tokenizedTopics.queryParameter      = '<%# QueryParameter %>';
    tokenizedTopics.resultLimit         = '<%# !String.IsNullOrEmpty(ResultLimit)? ResultLimit : "-1" %>';
    tokenizedTopics.tokenLimit          = <%# !String.IsNullOrEmpty(TokenLimit)? TokenLimit : "null" %>;
    tokenizedTopics.isAutoPostBack      = <%# IsAutoPostback.ToString().ToLower() %>;
    tokenizedTopics.selectedTopics      = <%# SelectedTopics %>;

  //Fire TokenizedTopics.prototype.getTokenizedTopics() (and $([selector]).tokenInput())
    tokenizedTopics.getTokenizedTopics();

  });

</script>