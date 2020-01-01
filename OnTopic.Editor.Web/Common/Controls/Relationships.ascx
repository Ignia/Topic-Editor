<%@ Control Language="C#" ClassName="Ignia.Topics.Relationships" Inherits="Ignia.Topics.Web.Editor.AttributeTypeControl" %>

<%@ Import Namespace="Ignia.Topics" %>

<Script RunAt="Server">

/*==============================================================================================================================
| Relationships Control
|
| Author        Hedley Robertson
| Client        Ignia
| Project       Topics Library
|
| Purpose       Implements a treeview for related item selection
|
>===============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               07.08.10        Hedley Robertson        Created initial version.
|               10.17.13        Jeremy Caney            Updated to use new AttributeTypeControl base class.
|               10.28.13        Jeremy Caney            Fixed issue with CheckAscendants; setup to display hidden topics.
>===============================================================================================================================
| ###TODO JJC081413: Need to refactor properties to better map to Relationships functionality.  E.g., Namespace should be
| labeled RelationshipType.  Additionally, a new property should be added that allows the Scope to be defined (e.g., this
| might be set to "Root:Categories:Models" for a "Model" content type that is intended to be cross-referenced with Model
| Categories.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| PUBLIC FIELDS
\-----------------------------------------------------------------------------------------------------------------------------*/
  public        string                          LabelName               = "";
  public        bool                            Enabled                 = true;
  public        string                          Scope                   = "";
  public        bool                            ShowRoot                = false;
  public        bool                            CheckAscendants         = false;

  public        string                          AttributeName           = "";
  public        string                          AttributeValue          = "";

  public        string                          ValidationGroup         = "";
  public        string                          Namespace               = "Related";

/*==============================================================================================================================
| PRIVATE FIELDS
\-----------------------------------------------------------------------------------------------------------------------------*/
  private       Dictionary<string, string>      _related                = new Dictionary<string, string>();

/*==============================================================================================================================
| DECLARE PRIVATE VARIABLES
>===============================================================================================================================
| Declare variables that will have a page scope
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| PROPERTY: VALUE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override String Value {
    get {
      return CleanArray(Field.Value);
      }
    set {
      Field.Value = CleanArray(value);
      }
    }

/*==============================================================================================================================
| METHOD: CLEAN ARRAY
>===============================================================================================================================
| Takes a string array, converts it to an array, strips any blank entries, and returns it to a string array.  Useful for
| dealing with potential artifacts such as empty array items introduced by JavaScript.
\-----------------------------------------------------------------------------------------------------------------------------*/
  string CleanArray(string value) {
    return String.Join(",", value.Split(new char[] {','}, StringSplitOptions.RemoveEmptyEntries));
    }

/*==============================================================================================================================
| PAGE LOAD
>===============================================================================================================================
| Handle all requests for page load, including state control based on user input
\-----------------------------------------------------------------------------------------------------------------------------*/
  void Page_Load(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | Bind Data Elements within Control
  \---------------------------------------------------------------------------------------------------------------------------*/
    this.DataBind();

    }

</Script>

<asp:HiddenField ID="Field" RunAt="Server" />
<asp:PlaceHolder ID="PHRequired" RunAt="Server" />
<asp:Panel ID="TreeView" RunAt="Server" />

<script type="text/javascript">
  Ext.onReady(function(){
    var Tree            = Ext.tree;
    var Storage         = Ext.get("<%= Field.ClientID %>");
    var relationships   = Storage.dom.value.split(",");

    tree = new Tree.TreePanel({
      id                : 'relatedTree',
      useArrows         : true,
      autoScroll        : true,
      animate           : true,
      enableDD          : false,
      containerScroll   : true,
      border            : false,
      baseCls           : 'RelationshipsTreeView',
      dataUrl           : 'Client/Topics.Json.aspx?ShowRoot=<%= ShowRoot.ToString() %>&ShowAll=true&RelatedNamespace=<%= Namespace %>&RelatedTopicID=<%= ((TopicPage)Page).Topic.Id%>&Scope=<%= Scope %>&AttributeName=<%= AttributeName %>&AttributeValue=<%= AttributeValue %>',
      root              : new Ext.tree.AsyncTreeNode({
        checked         : true,
        text            : 'Web',
        draggable       : false,
        id              : 'related',
        leaf            : false
        }),
      rootVisible       : false,
      listeners         : {
        click           : function(node) {
          node.checked  = true;
          node.select();
          return true;
          },
        checkchange     : function(node, checked) {
          if (checked) {
            relationships.push(node.attributes.id);
            }
          else {
            relationships.remove(node.attributes.id);
            }
          Storage.dom.value = relationships.concat(",");
          <%# CheckAscendants? "" : "return true" %>
          if (checked && node.parentNode) node.parentNode.getUI().toggleCheck(true);
          }
        }
      });
    tree.render('<%= TreeView.ClientID %>');

    });
</script>