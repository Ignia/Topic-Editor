<%@ Page Language="C#" ContentType="application/json" %>

<%@ Import NameSpace="System.Linq" %>
<%@ Import NameSpace="Topics=Ignia.Topics" %>

<script runat="server">

/*==============================================================================================================================
| TOPICS BRIDGE JSON
|
| Author:       Jeremy Caney, Ignia LLC (Jeremy.Caney@Ignia.com)
| Client:       Ignia
| Project:      Topics Editor
|
| Purpose:      The Topics Bridge generates JSON for the nodes in the topics system.
|
>===============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               05.28.10        Jeremy Caney            Created initial template based on resource editor bridge
|               07.09.10        Hedley Robertson        Modifications to support relationships via checkbox select on tree
|               10.13.13        Jeremy Caney            Provided considerable refactoring including improved filtering support.
|               03.27.15        Katherine Trunkey       Re-enabled JSON ContentType
|               03.27.15        Katherine Trunkey       Added FlattenStructure property and associated output logic.
|               03.27.15        Katherine Trunkey       Added UsePartialMatch property; added associated logic to the
|                                                       FilterChildren method in order to match Topics against a Contains()
|                                                       query, if specified.
|               04.01.15        Katherine Trunkey       Added ResultLimit property and associated logic to determine the
|                                                       maximum number of Topics to return.
|               04.07.15        Katherine Trunkey       Added filterValue logic to FilterChildren in order to account for
|                                                       AttributeName values that may not be retrievable via Attributes.GetValue().
|               04.09.15        Katherine Trunkey       Added HasAttribute() and GetAttribute() methods to centralize Topic
|                                                       filtering logic.
|               04.15.15        Katherine Trunkey       Added Query parameter and associated logic to perform a broader search
|                                                       against Topic properties and Attributes.
>===============================================================================================================================
| ###TODO JJC081413: Need to refactor properties to better map to Relationships functionality.  E.g., RelatedNamespace should be
| renamed to RelationshipType and Relationships_TopicID should be renamed to Source_TargetID.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| PAGE VARIABLES
\-----------------------------------------------------------------------------------------------------------------------------*/
  private       string          _scope                  = null;
  private       Topic           _rootTopic              = null;
  private       Topic           _relatedTopic           = null;
  private       string          _relatedNamespace       = null;
  private       int             _resultLimit            = -1;
  private       string          _attributeName          = null;
  private       string          _attributeValue         = null;
  private       string          _query                  = null;

/*==============================================================================================================================
| SCOPE
>-------------------------------------------------------------------------------------------------------------------------------
| Determines where the tree view should begin.  By default, assumes the root.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string Scope {
    get {
      if (_scope == null) {
        if (Request.QueryString["Scope"] != null && Request.QueryString["Scope"].Length > 0) {
          _scope = Request.QueryString["Scope"].ToString();
          }
        else {
          _scope = "Root";
          }
        }
      return _scope;
      }
    }

/*==============================================================================================================================
| ROOT TOPIC
>-------------------------------------------------------------------------------------------------------------------------------
| Gets the base topic to use for the JSON, based on the specified scope.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public Topic RootTopic {
    get {
      if (_rootTopic == null) {
        _rootTopic = TopicRepository.DataProvider.Load(Scope)?? new Topic();
        }
      return _rootTopic;
      }
    }

/*==============================================================================================================================
| RELATED TOPIC
>-------------------------------------------------------------------------------------------------------------------------------
| Allows the output to add checkboxes with selected values based on a related topic.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public Topic RelatedTopic {
    get {

      if (_relatedTopic == null && Request.QueryString["RelatedTopicID"] != null) {

        int     relatedTopicId  = -1;
        bool    loadRelated     = Int32.TryParse(Request.QueryString["RelatedTopicID"], out relatedTopicId);

        if (loadRelated) {
          _relatedTopic = TopicRepository.DataProvider.Load(relatedTopicId);
          if (_relatedTopic == null) {
            throw new ArgumentException("Failed to load Topic Id " + relatedTopicId.ToString() + " from cached repository");
            }
          }
        }

      return _relatedTopic;
      }
    }

/*==============================================================================================================================
| RELATED NAMESPACE
>-------------------------------------------------------------------------------------------------------------------------------
| If loading related data, determines the namespace of the related data to look for.  By default, it uses "Related", but there
| are multiple possible relationship sources it could be bound to instead.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string RelatedNamespace {
    get {
      if (_relatedNamespace == null) {
        _relatedNamespace = Request.QueryString["RelatedNamespace"]?? "Related";
        }
      return _relatedNamespace;
      }
    }

/*==============================================================================================================================
| LOAD RELATED
>-------------------------------------------------------------------------------------------------------------------------------
| Simple flag to help determine whether or not related values should be assessed or not.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool LoadRelated {
    get {
      return RelatedTopic != null;
      }
    }

/*==============================================================================================================================
| SHOW ROOT
>-------------------------------------------------------------------------------------------------------------------------------
| Determine whether or not the root passed should be displayed in the tree view, or if it should only display children.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool ShowRoot {
    get {
      return (Request.QueryString["ShowRoot"]?? "false").Equals("true", StringComparison.InvariantCultureIgnoreCase);
      }
    }

/*==============================================================================================================================
| SHOW ALL
>-------------------------------------------------------------------------------------------------------------------------------
| Determine whether or not hidden and inactive children should be displayed; typically used exclusively for the editor.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool ShowAll {
    get {
      return (Request.QueryString["ShowAll"]?? "false").Equals("true", StringComparison.InvariantCultureIgnoreCase);
      }
    }

/*==============================================================================================================================
| USE KEY AS TEXT
>-------------------------------------------------------------------------------------------------------------------------------
| Determines if the name should be displayed using the Title (if available) or the Key.  Defaults to Title.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool UseKeyAsText {
    get {
      return (Request.QueryString["UseKeyAsText"]?? "false").Equals("true", StringComparison.InvariantCultureIgnoreCase);
      }
    }

/*==============================================================================================================================
| IS RECURSIVE
>-------------------------------------------------------------------------------------------------------------------------------
| Determine whether grandchildren of the RootTopic should be displayed, or whether the tree should only show one tier of
| Topics.  Defaults to recursive.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool IsRecursive {
    get {
      return (Request.QueryString["IsRecursive"]?? "true").Equals("true", StringComparison.InvariantCultureIgnoreCase);
      }
    }

/*==============================================================================================================================
| FLATTEN STRUCTURE
>-------------------------------------------------------------------------------------------------------------------------------
| Determine whether all Topics should be added to the output at the same (top) level, or whether sub-tiers of Topics should
| be added to the output under a "children" array (of the parent).
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool FlattenStructure {
    get {
      return (Request.QueryString["FlattenStructure"]?? "false").Equals("true", StringComparison.InvariantCultureIgnoreCase);
      }
    }

/*==============================================================================================================================
| SHOW NESTED TOPICS
>-------------------------------------------------------------------------------------------------------------------------------
| Determine whether or not nested topics (i.e., topics within List ContentTypes) should be displayed or not.  By default, it
| is assumed that they should not be displayed.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool ShowNestedTopics {
    get {
      return (Request.QueryString["ShowNestedTopics"]?? "false").Equals("true", StringComparison.InvariantCultureIgnoreCase);
      }
    }

/*==============================================================================================================================
| USE PARTIAL MATCH
>-------------------------------------------------------------------------------------------------------------------------------
| If set, changes the FilterChildren query to find Topics based on a partial match against the specified AttributeName's
| AttributeValue, if both are present; otherwise, the query returns only exact matches.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool UsePartialMatch {
    get {
      return (Request.QueryString["UsePartialMatch"]?? "false").Equals("true", StringComparison.InvariantCultureIgnoreCase);
      }
    }

/*==============================================================================================================================
| RESULT LIMIT
>-------------------------------------------------------------------------------------------------------------------------------
| If set, should limit the number of Topics loaded/output to the JSON. Includes setter in order to be decremented along with
| resultLimit in AddNodeToOutput().
\-----------------------------------------------------------------------------------------------------------------------------*/
  public int ResultLimit {
    get {
      if (_resultLimit < 0 && Request.QueryString["ResultLimit"] != null) {
        int     resultLimit;
        bool    setLimit        = Int32.TryParse(Request.QueryString["ResultLimit"], out resultLimit);
        if (setLimit) {
          _resultLimit          = resultLimit;
          }
        }
      return _resultLimit;
      }
    set {
      _resultLimit               = value;
      }
    }

/*==============================================================================================================================
| ATTRIBUTE NAME
>-------------------------------------------------------------------------------------------------------------------------------
| May optionally filter out topics based on attribute values; if so, this property defines the attribute name.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string AttributeName {
    get {
      if (_attributeName == null && Request.QueryString["AttributeName"] != null) {
        _attributeName = Request.QueryString["AttributeName"];
        }
      return _attributeName;
      }
    }

/*==============================================================================================================================
| ATTRIBUTE VALUE
>-------------------------------------------------------------------------------------------------------------------------------
| May optionally filter out topics based on attribute values; if so, this property defines the attribute value.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string AttributeValue {
    get {
      if (_attributeValue == null && Request.QueryString["AttributeValue"] != null) {
        _attributeValue = Request.QueryString["AttributeValue"];
        }
      return _attributeValue;
      }
    }

/*==============================================================================================================================
| QUERY
>-------------------------------------------------------------------------------------------------------------------------------
| May optionally filter out topics based on attribute values; if so, this property defines the attribute value.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public string Query {
    get {
      if (_query == null && Request.QueryString["Query"] != null) {
        _query = Server.UrlDecode(Request.QueryString["Query"]);
        }
      return _query;
      }
    }

/*==============================================================================================================================
| PAGE INIT
\-----------------------------------------------------------------------------------------------------------------------------*/
  protected void Page_Init(object sender, EventArgs e) {

  /*============================================================================================================================
  | Generate the output the nodes recursively.
  \---------------------------------------------------------------------------------------------------------------------------*/
    string      output          = "[";

    if (ShowRoot) {
      output += AddNodeToOutput(RootTopic, 1, ResultLimit);
      }
    else {
      foreach (Topic topic in FilterChildren(RootTopic)) {
        output += AddNodeToOutput(topic, 1, ResultLimit);
        }
      }
    if (output.Length > 2) {
      output = output.Substring(0, output.Length-2) + "]";
      }
    else {
      output = output + "]";
      }

    Response.Write(output);
    }

/*==============================================================================================================================
| METHOD: CHECK NODE RELATIONSHIP
>===============================================================================================================================
| Adds the passed node along with all the child nodes to the output
\-----------------------------------------------------------------------------------------------------------------------------*/
  private bool IsRelated(Topic targetTopic) {
    return IsRelated(RelatedTopic, targetTopic);
    }

  private bool IsRelated(Topic sourceTopic, Topic targetTopic) {

  /*============================================================================================================================
  | Validate input
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (
      sourceTopic == null ||
      sourceTopic.Relationships == null ||
      !sourceTopic.Relationships.Contains(RelatedNamespace)
      ) {
      return false;
      }

  /*============================================================================================================================
  | Evaluate matches
  \---------------------------------------------------------------------------------------------------------------------------*/
    foreach(Topic topic in sourceTopic.Relationships[RelatedNamespace])   {
      if (topic.Id == targetTopic.Id) {
        return true;
        }
      }

  /*============================================================================================================================
  | Assume false
  \---------------------------------------------------------------------------------------------------------------------------*/
    return false;

    }

/*==============================================================================================================================
| FILTER CHILDREN
>-------------------------------------------------------------------------------------------------------------------------------
| Given a topic, applies any filters requested, including filtering out Nested Topics (!ShowNestedTopics) and filter by
| Attributes (AttributeName, AttributeValue).
\-----------------------------------------------------------------------------------------------------------------------------*/
  private IEnumerable<Topic> FilterChildren(Topic topic) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | Get filtered Topics
  \---------------------------------------------------------------------------------------------------------------------------*/
    var filteredTopics = (
      from      t in topic.Children.Sorted
      where
        (       ShowAll || (
                  !t.Attributes.GetValue("IsDisabled").Equals("1") &&
                  !t.Attributes.GetValue("IsHidden").Equals("1") &&
                  !t.Attributes.GetValue("IsInactive").Equals("1")
                  )
                ) &&
        (       ShowNestedTopics ||
                !t.Attributes.GetValue("ContentType").Equals("List")
                ) &&
        (       String.IsNullOrEmpty(AttributeName) ||
                String.IsNullOrEmpty(AttributeValue) ||
                HasAttribute((Topic)t)
                ) &&
        (       String.IsNullOrEmpty(Query) ||
                IsMatch((Topic)t)
                )
      select    t
      ).AsQueryable();

    return filteredTopics;
    }

/*==============================================================================================================================
| METHOD: HAS ATTRIBUTE
>===============================================================================================================================
| Specific filtering check based on AttributeName and AttributeValue; intended for use when the topic should be "filtered", but
| is not passed through FilterChildren().
\-----------------------------------------------------------------------------------------------------------------------------*/
  private bool HasAttribute(Topic topic) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | Check for partial or exact match based on UsePartialMatch setting
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (UsePartialMatch) {
      return (GetAttribute(topic, AttributeName).IndexOf(AttributeValue, StringComparison.InvariantCultureIgnoreCase) >= 0);
      }
    else {
      return GetAttribute(topic, AttributeName).Equals(AttributeValue, StringComparison.InvariantCultureIgnoreCase);
      }

    }

/*==============================================================================================================================
| METHOD: GET ATTRIBUTE
>===============================================================================================================================
| Simple helper method used by HasAttribute(); in the case of non-typical Topic AttributeValues (e.g., UniqueKey), sets the
| filter value based on the corresponding Topic property, otherwise defaults to GetAttribute(AttributeName).
\-----------------------------------------------------------------------------------------------------------------------------*/
  private string GetAttribute(Topic topic, string attributeName) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | Skip settings if AttributeName is unavailable
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (String.IsNullOrEmpty(attributeName)) return "";

  /*----------------------------------------------------------------------------------------------------------------------------
  | Set filter value to Topic property, if available, for non-typical Topic AttributeValues
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (attributeName.Equals("uniquekey", StringComparison.InvariantCultureIgnoreCase)) {
      return topic.UniqueKey;
      }
    else if (attributeName.Equals("title", StringComparison.InvariantCultureIgnoreCase)) {
      return topic.Title;
      }

  /*----------------------------------------------------------------------------------------------------------------------------
  | Default to GetAttribute(AttributeName)
  \---------------------------------------------------------------------------------------------------------------------------*/
    else {
      return topic.Attributes.GetValue(attributeName, "");
      }

    }

/*==============================================================================================================================
| METHOD: IS MATCH
>===============================================================================================================================
| Specific filtering check based on the Query value, if available. Splits the Query into individual terms, then loops through
| the Topic's Attributes to check whether there is a match against any of the individual Query terms.
\-----------------------------------------------------------------------------------------------------------------------------*/
  private bool IsMatch(Topic topic) {

    List<string>        attributeValues = GetQueryableAttributeValues(topic);
    List<string>        searchTerms     = Query.Split(new string[] {" "}, StringSplitOptions.RemoveEmptyEntries).ToList();

  /*----------------------------------------------------------------------------------------------------------------------------
  | Return boolean (true if the current Attributes list is a match against the current search term)
  \---------------------------------------------------------------------------------------------------------------------------*/
    return searchTerms.All(searchTerm => attributeValues.Any(attribute => attribute.IndexOf(searchTerm, 0, StringComparison.InvariantCultureIgnoreCase) >= 0));

    }

/*==============================================================================================================================
| METHOD: GET QUERYABLE ATTRIBUTE VALUES
>===============================================================================================================================
| Helper method to define a list of queryable (e.g., not WYSIWYG) Attributes for the provided Topic. Used when a Query value is
| provided and the IsMatch(topic) check is performed.
>===============================================================================================================================
| ###TODO KLT041515: Restrict Topic's queryable Attributes to not include Body (or WYSIWYG fields)?
\-----------------------------------------------------------------------------------------------------------------------------*/
  private List<string> GetQueryableAttributeValues(Topic topic) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | Define list of Attributes
  \---------------------------------------------------------------------------------------------------------------------------*/
    List<string>        attributeValues = new List<string>();

  /*----------------------------------------------------------------------------------------------------------------------------
  | Loop through Topic's Attributes and add their values to the list
  \---------------------------------------------------------------------------------------------------------------------------*/
    foreach (Topics.AttributeValue attributeValue in topic.Attributes) {
      attributeValues.Add(topic.Attributes.GetValue(attributeValue.Key));
      }

  /*----------------------------------------------------------------------------------------------------------------------------
  | Add Topic property values (for properties not typically or necessarily set to an AttributeValue)
  \---------------------------------------------------------------------------------------------------------------------------*/
  //Add UniqueKey
    attributeValues.Add(topic.UniqueKey);
  //Add Title
    attributeValues.Add(topic.Title);

  /*----------------------------------------------------------------------------------------------------------------------------
  | Return values
  \---------------------------------------------------------------------------------------------------------------------------*/
    return attributeValues;

    }

/*==============================================================================================================================
| METHOD: ADD NODE TO OUTPUT
>===============================================================================================================================
| Adds the passed node along with all the child nodes to the output
\-----------------------------------------------------------------------------------------------------------------------------*/
  private string AddNodeToOutput(Topic topic, int indentLevel, int resultLimit) {
    return AddNodeToOutput(topic, indentLevel, resultLimit, true);
    }

  private string AddNodeToOutput(Topic topic, int indentLevel, int resultLimit = -1, bool outputTopic = true) {

  /*============================================================================================================================
  | Define variables
  \---------------------------------------------------------------------------------------------------------------------------*/
    bool        isSelected      = IsRelated(topic);
    string      output          = "";
    string      indent          = "";

  /*============================================================================================================================
  | Get "filtered" topic and/or its children based on (flattened) structure setting
  \---------------------------------------------------------------------------------------------------------------------------*/
    var         filteredTopics  = FlattenStructure? topic.Children : FilterChildren(topic);

  /*============================================================================================================================
  | If the structure is flattened but the Topic should be filtered, check HasAttribute() (if AttributeName and AttributeValue
  | are used) or IsMatch() (if Query is used)
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (FlattenStructure) {
      if (!String.IsNullOrEmpty(AttributeName) && !String.IsNullOrEmpty(AttributeValue) && !String.IsNullOrEmpty(Query)) {
        outputTopic             = (HasAttribute(topic) && IsMatch(topic));
        }
      else if (!String.IsNullOrEmpty(AttributeName) && !String.IsNullOrEmpty(AttributeValue)) {
        outputTopic             = HasAttribute(topic);
        }
      else if (!String.IsNullOrEmpty(Query)) {
        outputTopic             = IsMatch(topic);
        }
      }

  /*============================================================================================================================
  | Check for max results setting; if it's set (> -1), decrement it, and once it hits 0 set outputTopic to false.
  >-----------------------------------------------------------------------------------------------------------------------------
  | ###NOTE KLT040915: We want to decrement to 0 if resultLimit > 0, but also make sure we're not catching the -1 and stopping
  | the recursion. Additionally, we need to make sure the count doesn't get reset when moving to the next sibling node; thus,
  | resultLimit is tracked to ResultLimit.
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (resultLimit > 0 && outputTopic) {
      resultLimit--;
      ResultLimit               = resultLimit;
      }
    else if (resultLimit == 0) {
      outputTopic               = false;
      }

  /*============================================================================================================================
  | Output Topic properties (if outputTopic = true)
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (outputTopic) {

    /*--------------------------------------------------------------------------------------------------------------------------
    | Define node
    \-------------------------------------------------------------------------------------------------------------------------*/
      output += indent + "{"
      + "\"id\":\""             + topic.Id                                                                          + "\", "
      + "\"key\":\""            + HttpUtility.HtmlAttributeEncode(topic.Key)                                        + "\", "
      + "\"text\":\""           + HttpUtility.HtmlAttributeEncode(UseKeyAsText? topic.Key : topic.Title)            + "\", "
      + "\"path\":\""           + HttpUtility.HtmlAttributeEncode(topic.UniqueKey)                                  + "\", "
      + "\"webPath\":\""        + HttpUtility.HtmlAttributeEncode(topic.GetWebPath())                                    + "\", "
      + "\"draggable\":\""      + TopicRepository.ContentTypes[topic.ContentType].Attributes.GetValue("DisableDelete").Equals("1").ToString().ToLower()  + "\", ";

    /*--------------------------------------------------------------------------------------------------------------------------
    | Handle relationships
    \-------------------------------------------------------------------------------------------------------------------------*/
      if (LoadRelated) {
        output += ""
        + "\"checked\": "       + isSelected.ToString().ToLower()                                                   +  ", ";
        }

      }

  /*============================================================================================================================
  | Handle child nodes
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (IsRecursive && filteredTopics.Count() > 0) {
    //If the output should be flattened, end the current node and start a new top-tier node per child; otherwise, assemble
    //children via the "children" array.
      if (outputTopic) output  += ((FlattenStructure)? "}," : "\"children\":[");
      foreach (Topic topicNode in filteredTopics) {
        output += AddNodeToOutput(topicNode, indentLevel+1, ResultLimit, (ResultLimit == -1 || ResultLimit > 0));
        }
      if (outputTopic) output  += ((FlattenStructure)? "" : "]");
      }

    else if (outputTopic) {
      output += " \"leaf\": \"true\"";
      }

  /*============================================================================================================================
  | Close output and return
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (outputTopic) output += "},\n";

    output = output.Replace("}},", "},").Replace(",}", "}").Replace(", }", "}");
    output = output.Replace("},\n},", "},");
    output = output.Replace(",\n]", "\n]");
    return output;

    }

</script>
