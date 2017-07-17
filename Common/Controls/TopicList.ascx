<%@ Control Language="C#" ClassName="TopicList" Inherits="Ignia.Topics.Web.Editor.AttributeTypeControl" %>

<%@ Import Namespace="Ignia.Topics" %>

<%@ Register TagPrefix="ITE" TagName="TopicLookup" Src="TopicLookup.ascx" %>

<Script RunAt="Server">

/*===========================================================================================================================
| CONTROL: TOPIC LIST
|
| Author:       Katherine Trunkey, Ignia LLC (Katherine.Trunkey@ignia.com)
| Client        Ignia
| Project       Topics Editor
|
| Purpose:      Provides a list of Topics under a child "List" Topic with the key corresponding to the configured Context
|               property.
|
>============================================================================================================================
| ###TODO JJC080314: Provide support for Nested Topic namespacing, by prefixing the key of each TopicList with an undercore.
>============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               09.13.13        Katherine Trunkey       Created initial version.
|               10.17.13        Jeremy Caney            Updated to use new AttributeTypeControl base class.
|               12.16.13        Jeremy Caney            Corrected bug when setting Nested Topic container.
\--------------------------------------------------------------------------------------------------------------------------*/

/*===========================================================================================================================
| PRIVATE FIELDS
\--------------------------------------------------------------------------------------------------------------------------*/
  private       bool                            _isDataBound            = false;
  private       Topic                           _topics                 = null;
  private       string                          _treePanelIdentifier    = null;
  private       bool                            _targetPopup            = true;

/*===========================================================================================================================
| PROPERTY: TOPIC
\--------------------------------------------------------------------------------------------------------------------------*/
  public Topic Topic { get; set; }

/*===========================================================================================================================
| PROPERTY: PAGE TOPIC
\--------------------------------------------------------------------------------------------------------------------------*/
  public Topic PageTopic {
    get {
      return ((TopicPage)Page).Topic;
      }
    }

/*===========================================================================================================================
| PROPERTY: IS NEW
>============================================================================================================================
| Determines if the topic should be treated as a new topic.  If so, the form will default to blank and, when saved, a new
| topic will be created.
\--------------------------------------------------------------------------------------------------------------------------*/
  public bool IsNew {
    get {
      return (Request.QueryString["Action"]?? "").Equals("Add");
      }
    }

/*===========================================================================================================================
| PROPERTY: CONTENT TYPES
>----------------------------------------------------------------------------------------------------------------------------
| Defines a list of Content Types that represent the types of Topics supported by this Topic List.  For instance, if the
| ContentTypes value is "Attribute,ContentType", then the TopicList should only allow users to create Topics of the type
| Attribute or ContentType.
\--------------------------------------------------------------------------------------------------------------------------*/
  public string ContentTypes {
    get;
    set;
    }

/*==============================================================================================================================
| TARGET POPUP
>-------------------------------------------------------------------------------------------------------------------------------
| Toggle to set whether or not to use a popup (modal window) when editing the Topic, rather than a full page.
\-----------------------------------------------------------------------------------------------------------------------------*/
  public bool TargetPopup {
    get {
      return _targetPopup;
      }
    set {
      _targetPopup = value;
      }
    }

/*===========================================================================================================================
| PROPERTY: TREE PANEL IDENTIFIER
>----------------------------------------------------------------------------------------------------------------------------
| Settable reference to the initializing variable for the topic list tree panel.
\--------------------------------------------------------------------------------------------------------------------------*/
  public string TreePanelIdentifier {
    get {
      if (_treePanelIdentifier == null) {
        _treePanelIdentifier = this.ClientID + "_tree";
        }
      return _treePanelIdentifier;
      }
    set {
      _treePanelIdentifier = value;
      }
    }

/*===========================================================================================================================
| PROPERTY: TOPICS
>----------------------------------------------------------------------------------------------------------------------------
| Provides a reference to the Nested Topics managed by the TopicList control. Nested Topics are "namespaced" by a Topic named
| after the Key of the TopicList attribute; i.e., if a TopicList called "Controls" is created, then a child topic named
| "Controls" will be added to the the parent topic. If this container does not exist, this property will automatically create
| the container.
\--------------------------------------------------------------------------------------------------------------------------*/
  public Topic Topics {
    get {

    /*-----------------------------------------------------------------------------------------------------------------------
    | GET CACHED INSTANCE
    \----------------------------------------------------------------------------------------------------------------------*/
      if (_topics != null) return _topics;

    /*-----------------------------------------------------------------------------------------------------------------------
    | VERIFY PAGE STATE
    >------------------------------------------------------------------------------------------------------------------------
    | If the page topic is new, there is no context to create a Nested Topics List container. In that scenario, we should
    | simply return a stub.
    \----------------------------------------------------------------------------------------------------------------------*/
      if (IsNew) return new Topic();

    /*-----------------------------------------------------------------------------------------------------------------------
    | VERIFY CONTEXT EXISTS
    >------------------------------------------------------------------------------------------------------------------------
    | If the Nested Topic List container does not exist, automatically create it as a placeholder; this will ensure that it
    | is available if and when new Nested Topics are created. It will also ensure that the object is available for data
    | binding in the templates, regardless of whether any Nested Topics actually exist yet.
    >------------------------------------------------------------------------------------------------------------------------
    | ###TODO JJC080314: Provide support for Nested Topic namespacing, by prefixing the key of each TopicList with an
    | undercore.
    \----------------------------------------------------------------------------------------------------------------------*/
      if (!PageTopic.Contains(Attribute.Key)) {
        Topic   topics          = Topic.Create(Attribute.Key, "List");

        topics.Parent           = PageTopic;
        TopicRepository.DataProvider.Save(topics);

        }

    /*-----------------------------------------------------------------------------------------------------------------------
    | LOOKUP CONTEXT
    \----------------------------------------------------------------------------------------------------------------------*/
      _topics = PageTopic[Attribute.Key];

    /*-----------------------------------------------------------------------------------------------------------------------
    | RETURN TOPICS LIST
    \----------------------------------------------------------------------------------------------------------------------*/
      return _topics;

      }
    }

/*===========================================================================================================================
| PAGE INIT
>============================================================================================================================
| Provide handling for functions that must run prior to page load.  This includes dynamically constructed controls.
\--------------------------------------------------------------------------------------------------------------------------*/
  void Page_Init(Object Src, EventArgs E) {

  /*-------------------------------------------------------------------------------------------------------------------------
  | BOOTSTRAP TOPICS
  >--------------------------------------------------------------------------------------------------------------------------
  | When the Topics collection is called, it will ensure that the Nested Topics collection is available, thus allowing data
  | binding in the templates regardless of whether any Nested Topics exist. To ensure this happens, we call the Topics
  | collection in Init. In practice, this property will likely be called elsewhere in the control, but the control should not
  | depend on that to ensure availability of the Nested Topics collection.
  \------------------------------------------------------------------------------------------------------------------------*/
    Topic nestedTopics = Topics;

  /*----------------------------------------------------------------------------------------------------------------------------
  | ENSURE INCLUSION OF CLIENT SCRIPT
    if (!Page.ClientScript.IsClientScriptIncludeRegistered("TopicList")) {
      Page.ClientScript.RegisterClientScriptInclude("TopicList", "Common/Scripts/TopicList.js");
      }
  \---------------------------------------------------------------------------------------------------------------------------*/

  /*-------------------------------------------------------------------------------------------------------------------------
  | BIND DATA ELEMENTS WITHIN CONTROL
  \------------------------------------------------------------------------------------------------------------------------*/
    this.DataBind();

    }

</Script>

<script type="text/javascript">
  var <%= TreePanelIdentifier %>;

  Ext.onReady(function(){
    var Tree            = Ext.tree;

  //track what nodes are moved
    var oldPosition     = null;
    var oldNextSibling  = null;
    var debugMessage    = "";

    <%= TreePanelIdentifier %>  = new Tree.TreePanel({
      useArrows                 : true,
      autoScroll                : true,
      animate                   : false,
      enableDD                  : true,
      containerScroll           : true,
      border                    : false,
      baseCls                   : 'TreeView',
      dataUrl                   : 'Client/Topics.Json.aspx?Scope=<%# PageTopic.UniqueKey + ":" + Attribute.Key %>&ShowAll=true',
      root                      : new Ext.tree.AsyncTreeNode({}),
      rootVisible               : false,
      listeners                 : {
        click                   : function(n) {
        <asp:PlaceHolder Visible=<%# !TargetPopup %> RunAt="Server">
          location.href = "?Path=" + n.attributes.path;
        </asp:PlaceHolder>
        <asp:PlaceHolder Visible=<%# TargetPopup %> RunAt="Server">
          initEditorModal(n.attributes.key, 'Default.aspx?Path=' + n.attributes.path + '&Modal=true', <%= TreePanelIdentifier %>_refresh);return false;
        </asp:PlaceHolder>
          },
        startdrag               : function(tree, node, event) {
          oldPosition           = node.parentNode.indexOf(node);
          oldNextSibling        = node.nextSibling;
          },
        nodedragover            : function(dragOverEvent) {
          return dragOverEvent.point !== "append";
          },
        movenode                : function(tree, node, oldParent, newParent, position) {

          var params            = {'node':node.id, 'delta':(position-oldPosition)};

        //Determine sibling ID to place node after, based off position
          var siblingId         = -1;
          if (position > 0) {
            siblingId           = newParent.childNodes[position-1].id;
            }

        //Ext.Msg.alert("Debugging", "Node: " + node.attributes.id + ", OldParent: " + oldParent.attributes.id + ", Parent: " + newParent.attributes.id + ", Sibling: " + siblingId);

          PageMethods.MoveNode(
            node.attributes.id,
            <%# Topics.Id %>,
            siblingId,
            function(result) {}
            );

          }
        }
      });

  <asp:PlaceHolder Visible=<%# !IsNew %> RunAt="Server">
    <%= TreePanelIdentifier %>.render('<%# TopicListContainer.ClientID %>');
  </asp:PlaceHolder>

    });

  function <%= TreePanelIdentifier %>_refresh() {
    <%= TreePanelIdentifier %>.getLoader().load(<%= TreePanelIdentifier %>.root);
    };

</script>

<asp:Panel ID="TopicListContainer" RunAt="Server" />

<asp:PlaceHolder Visible=<%# !IsNew %> RunAt="Server">
  <ITE:TopicLookup
    Scope               = "Configuration:ContentTypes"
    AttributeName       = "ContentType"
    AttributeValue      = "ContentType"
    AllowedKeys         = <%# ContentTypes %>
    Label               = "Add child Topic..."
    ValueProperty       = "Title"
    TargetUrl           = <%# "Default.aspx?ContentType={Topic}&Path=" + PageTopic.UniqueKey + ":" + Attribute.Key + "&Action=Add" %>
    TargetPopup         = <%# TargetPopup %>
    OnClientClose       = <%# TreePanelIdentifier + "_refresh" %>
    Visible             = <%# !IsNew %>
    RunAt               = "Server"
    />
</asp:PlaceHolder>

<asp:Panel Visible=<%# IsNew %> CssClass="alert alert-warning" RunAt="Server">
  Subtopics cannot be created until this topic has been saved. Save the topic, then add nested topics.
</asp:Panel>

<%--
<div id="EditorModal_<%= Attribute.Key %>" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-header">
      <h1 id="ModalTitle_<%= Attribute.Key %>" class="h3 Page-Title"><!-- determined by modal open script caller --></h1>
    </div>
    <div class="modal-content">
      <iframe id="EditorFrame_<%= Attribute.Key %>" src="" width="100%" marginheight="0" frameborder="0"><!-- iframe source determined by modal open script caller --></iframe>
    </div>
  </div>
</div>
--%>

<script>
  $(function() {

    $('[id^="EditorModal"]').on('hide.bs.modal', function (e) {
      <%= TreePanelIdentifier %>_refresh();
      });

    });
</script>