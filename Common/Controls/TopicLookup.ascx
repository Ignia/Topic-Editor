<%@ Control Language="C#" ClassName="TopicLookup" Inherits="Ignia.Topics.Web.Editor.AttributeTypeControl" %>

<%@ Import Namespace="Ignia.Topics" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>
<%@ Import Namespace="System.Collections.ObjectModel" %>

<Script RunAt="Server">

/*==============================================================================================================================
| TOPIC LOOKUP
|
| Author:       Katherine Trunkey, Ignia LLC (Katherine.Trunkey@ignia.com)
| Client        Ignia
| Project       Topics Editor
|
| Purpose:      Provide a list of Topics to the user interface, potentially filtered by scope and attribute.
|
>===============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               08.25.13        Katherine Trunkey       Created initial version.
|               10.02.13        Jeremy Caney            Resolved data binding issue w/ SelectedValue.
|               10.11.13        Jeremy Caney            Added support for filtering by topics and setting label.
|               10.12.13        Jeremy Caney            Made Topics public, allowing it to be set externally.
|               10.12.13        Katherine Trunkey       Added checks for blank selected value to OnSelectedIndexChanged
|               10.17.13        Jeremy Caney            Updated to use new AttributeTypeControl base class.
|               12.17.14        Jeremy Caney            Modified GetTargetUrl to only append TopicId parameter if a querystring
|                                                       is present (i.e., TargetUrl contains a "?").
|               12.17.14        Jeremy Caney            Added support for UseUniqueKey, to optionally disable key uniqueness.
|               12.18.14        Katherine Trunkey       Replaced GetTargetUrl() with ReplaceTokens(), allowing the parameterized
|                                                       token replacement to operate off TargetUrl or ValueProperty.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| PUBLIC MEMBERS
\-----------------------------------------------------------------------------------------------------------------------------*/
  public        string                          Label                   = "Select a Topic...";
  public        string                          CssClassRequired        = "Required";
  public        string                          CssClassLabel           = "FormField Label";
  public        string                          CssClassField           = "FormField Field";
  public        string                          ValidationGroup         = "";
  public        string                          AllowedKeys             = "";

/*==============================================================================================================================
| PRIVATE FIELDS
\-----------------------------------------------------------------------------------------------------------------------------*/
  private       bool                            _isDataBound            = false;
  private       string                          _value                  = null;
  private       string                          _scope                  = null;
  private       string                          _attributeName          = null;
  private       string                          _attributeValue         = null;

  private       string                          _targetUrl              = null;
  private       bool                            _targetPopup            = false;
  private       string                          _onClientClose          = null;
  private       bool                            _isLabelSet             = false;
  private       bool                            _useUniqueKey           = true;
  private       string                          _valueProperty          = null;

  private       Collection<Topic>               _topics                 = null;
  private       Dictionary<string, string>      _dataSource             = null;

/*==============================================================================================================================
| SCOPE
>-------------------------------------------------------------------------------------------------------------------------------
| Settable reference to the Topic scope (e.g., "Web") by which to filter the TopicSelection list.
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
| Settable reference to the Attribute Name (e.g., "ContentType") by which to filter the TopicSelection list. Both AttributeName
| and AttributeValue are required for use.
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
| Settable reference to the Attribute Value (e.g., "Page") by which to filter the TopicSelection list. Both AttributeName and
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
| TARGET URL
>-------------------------------------------------------------------------------------------------------------------------------
| The TargetUrl allows the dropdown control to trigger the loading of a new page based on the value of the dropdown box.  The
| new page is loaded using the LoadPage event handler, and may optionally be handled as a redirect (default) or a popup
| (based on the TargetPopup boolean).
>-------------------------------------------------------------------------------------------------------------------------------
| ###TODO JJC092313: Need to add support for {token} replacements in the TargetUrl.  Also, unclear what the current default
| logic is doing; I don't believe this should be necessary.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string TargetUrl {
    get {
      return _targetUrl;
      }
    set {
      _targetUrl = value;
      }
    }

/*==============================================================================================================================
| TARGET POPUP
>-------------------------------------------------------------------------------------------------------------------------------
| If a TargetUrl is supplied, and TargetPopup is set to true, then the TargetUrl will be loaded during the LoadPage event as
| a popup window.  Otherwise, the TargetUrl will be loaded via a redirect.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool TargetPopup {
    get {
      return _targetPopup;
      }
    set {
      _targetPopup = value;
      if (!value) TopicSelectionRequiredValidator.Enabled = false;
      }
    }

/*==============================================================================================================================
| ON CLIENT CLOSE
>-------------------------------------------------------------------------------------------------------------------------------
| If supplied, sets a reference to a callback function to execute on close of the editor popup.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string OnClientClose {
    get {
      return _onClientClose;
      }
    set {
      _onClientClose = value;
      }
    }

/*==============================================================================================================================
| PROPERTY: USE UNIQUE KEY
>-------------------------------------------------------------------------------------------------------------------------------
| Determines whether to use a fully qualified key ("UniqueKey") or just the topic key. A UniqueKey makes it easier to construct
| or retrieve the corresponding topic object without any knowledge of where that object exists. Further, under certain
| circumstances, a UniqueKey may be necessary to guarantee uniqueness (for instance, if DataSource is overridden with a
| collection of topics from multiple locations in the topic tree). That said, the topic key may be a preferred value,
| particularly when not intended to provide a strongly-typed reference to particular topics (e.g., when the LookupList is being
| used to simply provide a constrained list of known values, such as tags).
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool UseUniqueKey {
    get {
      return _useUniqueKey;
      }
    set {
      _useUniqueKey = value;
      }
    }

/*==============================================================================================================================
| VALUE PROPERTY
>-------------------------------------------------------------------------------------------------------------------------------
| Determines what property to bind the TopicLookup/TopicList to.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string ValueProperty {
    get {
      if (_valueProperty == null) {
        _valueProperty = UseUniqueKey? "UniqueKey" : "Key";
        }
      return _valueProperty;
      }
    set {
      _valueProperty = value;
      }
    }

/*==============================================================================================================================
| PROPERTY: VALUE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override String Value {
    get {
      return TopicSelection.SelectedValue;
      }
    set {
      _value = value;
      }
    }

/*==============================================================================================================================
| PROPERTY: REQUIRED
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override bool Required {
    get {
      return TopicSelectionRequiredValidator.Enabled;
      }
    set {
      TopicSelectionRequiredValidator.Enabled = value;
      if (value && !_targetPopup) {
        TopicSelection.CssClass = CssClassRequired;
        }
      else {
        TopicSelection.CssClass = CssClassField;
        }
      }
    }

/*==============================================================================================================================
| PROPERTY: TOPICS
>-------------------------------------------------------------------------------------------------------------------------------
| Retrieves a collection of topics with optional control call filter properties Scope, AttributeName and AttributeValue.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public Collection<Topic> Topics {
    get {

    /*--------------------------------------------------------------------------------------------------------------------------
    | GET CACHED INSTANCE
    \-------------------------------------------------------------------------------------------------------------------------*/
      if (_topics != null) return _topics;

    /*--------------------------------------------------------------------------------------------------------------------------
    | INSTANTIATE OBJECTS
    \-------------------------------------------------------------------------------------------------------------------------*/
      Collection<Topic> topics          = new Collection<Topic>();
      Topic             topic           = new Topic();

      if (Scope != null) {
        topic                           = TopicRepository.RootTopic.GetTopic(Scope);
        }

    //Use RootTopic if Scope is available but does not return a topic object
      if (topic == null) {
        topic                           = TopicRepository.RootTopic;
        }

    /*--------------------------------------------------------------------------------------------------------------------------
    | FILTER TOPICS SELECTION LIST BY ATTRIBUTENAME/ATTRIBUTEVALUE
    \-------------------------------------------------------------------------------------------------------------------------*/
      if (AttributeName != null && AttributeValue != null) {
        topics                          = topic.FindAllByAttribute(AttributeName, AttributeValue);
        }

    /*--------------------------------------------------------------------------------------------------------------------------
    | GET ALL TOPICS UNDER ROOTTOPIC
    \-------------------------------------------------------------------------------------------------------------------------*/
      if (topics.Count == 0) {
        foreach (Topic childTopic in topic) {
          topics.Add(childTopic);
          }
        }

    /*--------------------------------------------------------------------------------------------------------------------------
    | FILTER TOPICS SELECTION LIST BASED ON CONTENT TYPES
    \-------------------------------------------------------------------------------------------------------------------------*/
      string[]          allowedKeys     = null;
      if (!String.IsNullOrEmpty(AllowedKeys)) {
        allowedKeys                     = AllowedKeys.Split(',');
        for (int i=0; i < topics.Count; i++) {
          Topic         childTopic      = topics[i];
          if (Array.IndexOf(allowedKeys, childTopic.Key) < 0) {
            topics.RemoveAt(i);
            i--;
            }
          }
        }

    /*--------------------------------------------------------------------------------------------------------------------------
    | RETURN TOPICS LIST
    \-------------------------------------------------------------------------------------------------------------------------*/
      _topics = topics;
      return _topics;
      }

    set {
      _topics = value;
      }

    }

/*==============================================================================================================================
| PROPERTY: DATASOURCE
>-------------------------------------------------------------------------------------------------------------------------------
| Provides an intermediary data store of topic keys and transformed target URLs to use for the dropdownlist option values
| and text.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public Dictionary<string, string> DataSource {
    get {
      if (_dataSource != null) return _dataSource;
      Dictionary<string, string> dataSource     = new Dictionary<string, string>();

    /*--------------------------------------------------------------------------------------------------------------------------
    | ADD TOPIC KEY AND URL VALUE IF NOT ALREADY IN THE DICTIONARY
    \-------------------------------------------------------------------------------------------------------------------------*/
      foreach (Topic topic in Topics) {
        if (!dataSource.Keys.Contains(topic.Key)) {
          string        key                     = topic.Title;
          string        value                   = "";

          if (!String.IsNullOrEmpty(TargetUrl)) {
          //Add TopicID if not already available
            if (TargetUrl.IndexOf("?") >= 0 && TargetUrl.IndexOf("TopicID", StringComparison.InvariantCultureIgnoreCase) < 0) {
              TargetUrl                        += "&TopicID=" + topic.Id.ToString();
              }
            value                               = ReplaceTokens(topic, TargetUrl);
            }
          else {
            value                               = ReplaceTokens(topic, "{" + ValueProperty + "}");
            }

          dataSource.Add(key, value);
          }
        }

    /*--------------------------------------------------------------------------------------------------------------------------
    | RETURN DATASOURCE ITEMS
    \-------------------------------------------------------------------------------------------------------------------------*/
      _dataSource                               = dataSource;
      return _dataSource;

      }
    }

/*===========================================================================================================================
| PAGE INIT
>============================================================================================================================
| Provide handling for functions that must run prior to page load.  This includes dynamically constructed controls.
\--------------------------------------------------------------------------------------------------------------------------*/
  void Page_Init(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | BIND CONTROL
  \---------------------------------------------------------------------------------------------------------------------------*/
    this.DataBind();

  /*----------------------------------------------------------------------------------------------------------------------------
  | POPULATE DROPDOWNLIST
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (Topics.Count > 1) {
      TopicSelection.DataTextField      = "Key";
      TopicSelection.DataValueField     = "Value";
      TopicSelection.DataSource         = DataSource;
      TopicSelection.DataBind();
      }

    }

/*==============================================================================================================================
| PAGE LOAD
>===============================================================================================================================
| Fires when page loads; has access to form and post back values.
\-----------------------------------------------------------------------------------------------------------------------------*/
  void Page_Load(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | HANDLE POPUP
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (TargetPopup && TopicSelection != null) {
      TopicSelection.Attributes.Add("onchange", "editInPopup(this[this.selectedIndex].value, " + OnClientClose + "); return false;");
      foreach (ListItem item in TopicSelection.Items) {
        if (String.IsNullOrEmpty(item.Value)) continue;
      //item.Value                      = GetTargetUrl(item.Value);
        item.Value                      = ReplaceTokens(item.Value);

        }
      }

    }

/*==============================================================================================================================
| EVENT HANDLER: SET DEFAULT VALUES
>-------------------------------------------------------------------------------------------------------------------------------
| On databinding of the TopicSelection dropdownlist, sets intial (blank) "Select..." item and selected value, if available.
\-----------------------------------------------------------------------------------------------------------------------------*/
  protected void SetDefaultValues(Object sender, EventArgs e) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | INSERT LABEL AS INITIAL ITEM
  \---------------------------------------------------------------------------------------------------------------------------*/
    TopicSelection.Items.Insert(0, new ListItem(Label, ""));

  /*----------------------------------------------------------------------------------------------------------------------------
  | SET SELECTED INDEX, IF AVAILABLE FROM VALUE
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (TopicSelection.Items.FindByValue(_value) != null) {
      TopicSelection.SelectedValue      = _value;
      }

    }

/*==============================================================================================================================
| EVENT HANDLER: LOAD PAGE
>-------------------------------------------------------------------------------------------------------------------------------
| Refreshes the page with Path and/or TopicID TargetUrl querystring parameters updated with selected values.
\-----------------------------------------------------------------------------------------------------------------------------*/
  protected void LoadPage(Object sender, EventArgs e) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | VALIDATE INPUT
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (String.IsNullOrEmpty(TargetUrl) || String.IsNullOrEmpty(TopicSelection.SelectedValue)) return;

  /*----------------------------------------------------------------------------------------------------------------------------
  | GET SELECTED TOPIC
  \---------------------------------------------------------------------------------------------------------------------------*/
    Topic               targetTopic     = TopicRepository.RootTopic.GetTopic(((Scope!= null)? Scope + ":" : "") + TopicSelection.SelectedValue);

  /*----------------------------------------------------------------------------------------------------------------------------
  | PERFORM REDIRECT
  \---------------------------------------------------------------------------------------------------------------------------*/
    Response.Redirect(TopicSelection.SelectedValue);
    return;

    }


/*==============================================================================================================================
| REPLACE TOKENS
>-------------------------------------------------------------------------------------------------------------------------------
| Replaces tokenized parameters (e.g., {Key}) in the source string based on the source Topic's properties.
\-----------------------------------------------------------------------------------------------------------------------------*/
  private string ReplaceTokens(string topicKey) {
    return ReplaceTokens(Topics.Where(topic => topic.Key.Equals(topicKey)).FirstOrDefault(), "");
    }

  private string ReplaceTokens(Topic topic, string source, string defaultValue = null) {

    string      replacementToken        = (!String.IsNullOrEmpty(source)? source : (!String.IsNullOrEmpty(TargetUrl)? TargetUrl : ValueProperty));
    string      replacementValue        = "";

    if (topic != null && !String.IsNullOrEmpty(replacementToken)) {

      replacementValue                  = replacementToken
        .Replace("{Topic}", topic.Key)
        .Replace("{TopicId}", topic.Id.ToString())
        .Replace("{Name}", topic.Key)
        .Replace("{FullName}", topic.UniqueKey)
        .Replace("{Key}", topic.Key)
        .Replace("{UniqueKey}", topic.UniqueKey)
        .Replace("{Title}", topic.Title);

      }

    return replacementValue;
    }

/*==============================================================================================================================
| GET TOPIC TITLE
>-------------------------------------------------------------------------------------------------------------------------------
| Retrieves the Topic's Title property given the provided Topic Key string.
\-----------------------------------------------------------------------------------------------------------------------------*/
  private String GetTopicTitle(string topicKey) {
    Topic selectedTopic                 = Topics.Where(topic => topic.Title.Equals(topicKey)).FirstOrDefault();
    return (selectedTopic != null? selectedTopic.Title : "");
    }

</Script>

<asp:DropDownList
  ID                                    = "TopicSelection"
  OnDataBound                           = "SetDefaultValues"
  OnSelectedIndexChanged                = "LoadPage"
  AutoPostBack                          = <%# !TargetPopup && !String.IsNullOrEmpty(TargetUrl) %>
  Visible                               = <%# DataSource.Count > 1 %>
  RunAt                                 = "Server"
  />
<asp:RequiredFieldValidator
  ID                                    = "TopicSelectionRequiredValidator"
  Visible                               = <%# (TopicSelection != null) %>
  ControlToValidate                     = "TopicSelection"
  Enabled                               = "False"
  ValidationGroup                       = <%# ValidationGroup %>
  RunAt                                 = "Server"
  />

<asp:PlaceHolder ID="ChildTopicLink" Visible=<%# (DataSource.Count == 1 && !String.IsNullOrEmpty(TargetUrl)) %> RunAt="Server">
  <div class="ChildTopic">
    <!-- <%# Label %> -->
  <asp:PlaceHolder Visible=<%# !TargetPopup %> RunAt="Server">
    <a href="<%= DataSource.FirstOrDefault().Value %>" class="btn btn-info btn-sm">
  </asp:PlaceHolder>
  <asp:PlaceHolder Visible=<%# TargetPopup %> RunAt="Server">
    <a onclick="initEditorModal('<%= GetTopicTitle(DataSource.FirstOrDefault().Key) %>', '<%= DataSource.FirstOrDefault().Value %>&Modal=true', <%# OnClientClose %>); return false;" class="btn btn-info btn-sm">
  </asp:PlaceHolder>
      Add <%= GetTopicTitle(DataSource.FirstOrDefault().Key) %>
    </a>
  </div>
</asp:PlaceHolder>