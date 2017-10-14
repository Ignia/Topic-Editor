<%@ Control Language="C#" ClassName="TopicPointer" Inherits="Ignia.Topics.Web.Editor.AttributeTypeControl" %>

<%@ Import Namespace="Ignia.Topics" %>

<%@ Register TagPrefix="ITE" TagName="TokenizedTopicList" Src="TokenizedTopicList.ascx" %>

<Script RunAt="Server">

/*==============================================================================================================================
| CONTROL: TOPIC POINTER
|
| Author:       Katherine Trunkey, Ignia LLC (Katherine.Trunkey@ignia.com)
| Client:       Ignia
| Project:      Topics Editor
|
| Purpose:
|
>===============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               04.02.15        Katherine Trunkey       Created initial version.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| PRIVATE FIELDS
\-----------------------------------------------------------------------------------------------------------------------------*/
  private       string          _scope                          = null;
  private       string          _resultLimit                    = null;
  private       Topic           _pageTopic                      = null;
  private       string          _contentType                    = null;
  private       string          _value                          = "";

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
| PAGE TOPIC
\-----------------------------------------------------------------------------------------------------------------------------*/
  public Topic PageTopic {
    get {
      if (_pageTopic == null) {
        _pageTopic = ((TopicPage)Page).Topic;
      }
      return _pageTopic;
    }
    set {
      _pageTopic = value;
    }
  }

/*==============================================================================================================================
| VALUE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override String Value {
    get {
      return _value;
    }
    set {
      _value = value;
    }
  }

/*==============================================================================================================================
| IS NEW
>===============================================================================================================================
| Determines if the topic should be treated as a new topic.  If so, the form will default to blank and, when saved, a new
| topic will be created.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool IsNew {
    get {
      return (Request.QueryString["Action"]?? "").Equals("Add");
    }
  }

/*==============================================================================================================================
| CONTENT TYPE
>-------------------------------------------------------------------------------------------------------------------------------
| Settable reference for the Content Type (Key) to search against; should be set/overridden in DefaultConfiguration.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string ContentType {
    get {
      if (_contentType == null && PageTopic != null) {
        _contentType = PageTopic.Attributes.GetValue("ContentType");
      }
      return _contentType;
    }
    set {
      _contentType = value;
    }
  }

/*==============================================================================================================================
| PAGE INIT
\-----------------------------------------------------------------------------------------------------------------------------*/
  void Page_Init(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | Check PageTopic for TopicID Attribute - if available, set Value
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (PageTopic != null && !String.IsNullOrEmpty(PageTopic.Attributes.GetValue("TopicID"))) {
      Value                     = PageTopic.Attributes.GetValue("TopicID");
    }

  /*----------------------------------------------------------------------------------------------------------------------------
  | Bind data elements within control
  \---------------------------------------------------------------------------------------------------------------------------*/
    this.DataBind();

  }

/*==============================================================================================================================
| PAGE LOAD
\-----------------------------------------------------------------------------------------------------------------------------*/
  void Page_Load(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | Handle Topic pointer selection postback
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (Page.IsPostBack) {

    //Check the __EVENTTARGET to make sure it and the __EVENTARGUMENT are populated from TopicPointer
      if (
        !String.IsNullOrEmpty(Request["__EVENTTARGET"]) &&
        (Request["__EVENTTARGET"]).ToString().IndexOf("TopicPointer", StringComparison.InvariantCultureIgnoreCase) >= 0 &&
        !String.IsNullOrEmpty(Request["__EVENTARGUMENT"])
        ) {

      //Set Topic Pointer with selected Topic ID
        int selectedTopicId;
        if (Int32.TryParse(Request["__EVENTARGUMENT"], out selectedTopicId)) {
          SetTopicPointer(selectedTopicId);
        }

      }
    }
  }

/*==============================================================================================================================
| SET TOPIC POINTER
>-------------------------------------------------------------------------------------------------------------------------------
| Uses the selected Topic ID to set the TokenizedTopicList's Value property, get the selected Topic's Attributes,
\-----------------------------------------------------------------------------------------------------------------------------*/
  private void SetTopicPointer(int selectedTopicId) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | Set the Value for SelectedTopics
  \---------------------------------------------------------------------------------------------------------------------------*/
    Value                       = selectedTopicId.ToString();

  /*----------------------------------------------------------------------------------------------------------------------------
  | If the Topic is not new, set the TopicID Attribute for the current (Page) Topic; otherwise, create and save a new Topic
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (!IsNew) {
      PageTopic.Attributes.SetValue("TopicID", selectedTopicId.ToString());
    }
    else {

    //Get selected Topic from the Topic Repository
      Topic     selectedTopic   = TopicRepository.RootTopic.GetTopic(selectedTopicId);

    //Create new/temporary Topic
      Topic     derivedTopic    = new Topic();

    //Set (topic pointer) derivation
      derivedTopic.DerivedTopic = selectedTopic;

    //Set Key
      derivedTopic.Key          = selectedTopic.Key;
      derivedTopic.Attributes.SetValue("Key", selectedTopic.Key);

    //Set ContentType
      derivedTopic.ContentType  = selectedTopic.Attributes.GetValue("ContentType");
      derivedTopic.Attributes.SetValue("ContentType", selectedTopic.Attributes.GetValue("ContentType"));

    //Set Parent
      derivedTopic.Parent       = PageTopic;
      derivedTopic.Attributes.SetValue("ParentID", PageTopic.Id.ToString());

    //Double-check there are no siblings with the same Key; if there are, add time stamp to Key to differentiate
      foreach (Topic topic in derivedTopic.Parent.Children) {
        if (derivedTopic.Key == topic.Key) {
          derivedTopic.Key     += "_" + DateTime.Now.ToString("yyyyMMddHHmmss");
        }
      }

    //Save Topic
      TopicRepository.DataProvider.Save(derivedTopic);

    //Close modal
      StringBuilder     closeModalScript = new StringBuilder();
      closeModalScript.Append("console.log('Saved derived Topic: " + PageTopic.UniqueKey + "');");
      closeModalScript.Append("window.parent.closeModal()");
      ScriptManager.RegisterClientScriptBlock(this.Page, this.GetType(), "CloseDerivedTopicOnSave", closeModalScript.ToString(), true);

    }

  /*----------------------------------------------------------------------------------------------------------------------------
  | Re-bind control
  \---------------------------------------------------------------------------------------------------------------------------*/
    this.DataBind();

  /*----------------------------------------------------------------------------------------------------------------------------
  | Exit
  \---------------------------------------------------------------------------------------------------------------------------*/
    return;

  }

</Script>

<ITE:TokenizedTopicList
  ID                            = "TokenizedTopicPointer"
  Value                         = <%# Value %>
  AttributeName                 = "ContentType"
  AttributeValue                = <%# ContentType %>
  SearchProperty                = "text"
  QueryParameter                = "Query"
  ResultLimit                   = <%# ResultLimit?? "-1" %>
  TokenLimit                    = "1"
  IsAutoPostback                = "true"
  RunAt                         = "Server"
  />