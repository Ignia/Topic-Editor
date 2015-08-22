<%@ Page Language="C#" Title="Ignia OnTopic" EnableViewState="true" EnableValidation="false" EnableEventValidation="false" AutoEventWireup="true" ValidateRequest="False" CodeFile="Default.aspx.cs" Inherits="TopicsEditorPage" MasterPageFile="Common/Templates/Page.Layout.Master" %>

<%@ MasterType virtualPath="Common/Templates/Page.Layout.Master" %>

<%@ Import Namespace="Ignia.Topics" %>

<%@ Register TagPrefix="Ignia"  TagName="ClientValidation"      Src="/Common/Global/Controls/ClientValidation.ascx" %>
<%@ Register TagPrefix="ITE"    TagName="Relationships"         Src="Common/Controls/Relationships.ascx" %>
<%@ Register TagPrefix="ITE"    TagName="TopicLookup"           Src="Common/Controls/TopicLookup.ascx" %>
<%@ Register TagPrefix="ITE"    TagName="TokenizedTopicList"    Src="Common/Controls/TokenizedTopicList.ascx" %>

<asp:Content ContentPlaceHolderId="PageHead" runat="Server">
  <base target="_self" />

  <asp:PlaceHolder Visible=<%# !Master.IsModal %> RunAt="Server">
    <script>
      var tree;
      var rootTopicId = 0;

      Ext.onReady(function(){
        var Tree = Ext.tree;

        var currentTopic = "<%= Topic.UniqueKey %>";
        var currentPosition = currentTopic.indexOf(":", 5);

      //track what nodes are moved
        var oldPosition = null;
        var oldNextSibling = null;

        tree = new Tree.TreePanel({
          useArrows             : true,
          autoScroll            : true,
          animate               : true,
          enableDD              : true,
          containerScroll       : true,
          border                : false,
          baseCls               : 'TreeView',
          dataUrl               : 'Client/Topics.Json.aspx?ShowAll=true&UseKeyAsText=true',
          root                  : new Ext.tree.AsyncTreeNode({
            text                : 'Web',
            draggable           : false,
            id                  : rootTopicId
            }),
          rootVisible           : false,
          listeners             : {

            click               : function(n) {
              location.href = "?Path=" + n.attributes.path;
              },

            load                : function(n) {
              if (!n) return;
              if (currentPosition < 0) {
                currentPosition = currentTopic.length;
                }
              var currentNode = n;
              if (currentPosition <= currentTopic.length && currentPosition >= 0) {
                currentNode = currentNode.findChild("path", currentTopic.substring(0, currentPosition));
                if (currentPosition == currentTopic.length) {
                  currentPosition++;
                  }
                else {
                  currentPosition = currentTopic.indexOf(":", currentNode.attributes.path.length + 1);
                  }
                if (currentPosition < 0) {
                  currentPosition = currentTopic.length;
                  }
                if (currentNode.hasChildNodes() && !currentNode.isExpanded()) {
                  currentNode.expand(false);
                  return;
                  }
                }
              currentNode.ensureVisible();
              tree.selectPath(
                currentNode.getPath("text"),
                "text"
                );
              currentNode.select(currentNode);
              },

            startdrag           : function(tree, node, event){
              node.draggable = (node.attributes.draggable == "false");
              oldPosition = node.parentNode.indexOf(node);
              oldNextSibling = node.nextSibling;
              },

            movenode            : function(tree, node, oldParent, newParent, position) {
              if (oldParent == newParent){
                var params = {'node':node.id, 'delta':(position-oldPosition)};
                }
              else {
                var params = {'node':node.id, 'parent':newParent.id, 'position':position};
                }

            //Determine sibling ID to place node after, based off position
              var siblingId = -1;
              if (position > 0) {
                siblingId = newParent.childNodes[position-1].id; // TODO: double check indexing here
                }

            //Ext.Msg.alert("Debugging", "Node: " + node.attributes.id + ", Parent: " + newParent.attributes.id + ", Sibling: " + siblingId);

              console.log("Node: " + node.attributes.id + ", Parent: " + newParent.attributes.id + ", Sibling: " + siblingId);

              PageMethods.MoveNode(
                node.attributes.id,
                newParent.attributes.id,
                siblingId,
                function(result) {}
                );

              }
            }

          });

        tree.render('TreeView');

        });

      var rootTopicId = '<%= TopicRepository.RootTopic.Id %>';

    </script>
  </asp:PlaceHolder>



</asp:Content>

<asp:Content ContentPlaceHolderID="PageTitleArea" RunAt="Server">
  <!-- Page Title -->
  <h2 class="<%# ((Master.IsModal)? "h4" : "h3") %> Page-Title"><%# Topic.Title %></h2>
</asp:Content>

<asp:Content ContentPlaceHolderId="Tier2NavigationContainer" RunAt="Server">

  <div id="TreeView"></div>

  <asp:Panel class="Add-Topic" Visible=<%# !GetAttributeAsBool(ContentType, "DisableChildTopics", false) %> RunAt="Server">
    <ITE:TopicLookup
      ID                = "TopicLookupControl"
      Label             = "Add new..."
      Scope             = "Configuration:ContentTypes"
      Topics            = <%# ContentType.Relationships.Contains("ContentTypes")? ContentType.Relationships["ContentTypes"] : null %>
      AttributeName     = "ContentType"
      AttributeValue    = "ContentType"
      TargetUrl         = <%# "Default.aspx?ContentType={Topic}&Path=" + Topic.UniqueKey + "&Action=Add" %>
      RunAt             = "Server"
      />
  </asp:Panel>

</asp:Content>

<asp:Content ID="ContentCP" ContentPlaceHolderId="Content" Runat="Server">

  <asp:ScriptManager EnablePageMethods="True" ScriptMode="Release" RunAt="Server" />

  <!-- Editor Area -->
  <div id="<%# ((Master.IsModal)? "Modal_" : "") %>DynamicForm">

    <!-- Toolbar (Topic Display Group Tabs, Action Buttons) -->
    <div class="row Toolbar-Area">
      <div class="col-md-12">

        <div role="navigation" class="Editor-Navbar" style="position:fixed;z-index:50;padding-top:10px">

          <!-- Editor Actions (Save, Delete) -->
          <div class="Actions Top">

            <!-- Version Rollback -->
            <asp:ListView ID="VersionsListView" RunAt="Server">
              <LayoutTemplate>
                <div id="VersionsDropdown" class="dropdown" style="display:inline-block;">
                  <button class="btn btn-sm btn-ancillary dropdown-toggle" type="button" id="VersionsButton" data-toggle="dropdown">
                    <span class="glyphicon glyphicon-repeat small"></span>
                    Versions
                    <span class="caret"></span>
                  </button>
                  <ul class="dropdown-menu" role="menu" aria-labelledby="VersionsButton" style="left: 3px; top: 98%;">
                    <asp:Placeholder ID="itemPlaceholder" RunAt="Server" />
                  </ul>
                </div>
              </LayoutTemplate>
              <ItemTemplate>
                <li role="presentation" class="small">
                  <asp:LinkButton
                    Text                = <%# Eval("Key") %>
                    OnClick             = "SetTopicVersion"
                    CommandArgument     = <%# Eval("Value") %>
                    role                = "menuitem"
                    tabindex            = "-1"
                    RunAt               = "Server"
                    />
                </li>
              </ItemTemplate>
            </asp:ListView>
            <!-- /Version Rollback -->

            <button id="ModalCloseButton" type="button" Visible=<%# Master.IsModal %> class="btn btn-ancillary btn-sm" data-dismiss="modal" ClientIDMode="Static" RunAt="Server">Cancel</button>
            <asp:PlaceHolder Visible=<%# Topic.Parent.ContentType.Key.Equals("List") && !Master.IsModal %> RunAt="Server">
              <a href="Default.aspx?Path=<%# ((IsNew)? Topic.Parent.UniqueKey : ((Topic.Parent.Parent != null)? Topic.Parent.Parent.UniqueKey : "#")) %>"class="btn btn-ancillary btn-sm">Cancel</a>
            </asp:PlaceHolder>

            <button id="DeletePageButtonTop" Visible=<%# !IsNew %> Disabled=<%# DisableDelete || ContentType.Attributes.Get("DisableDelete").Equals("1") %> class="btn btn-default btn-sm" onclick="if (!confirmDelete()) return false;" onserverclick="DeleteTopic" RunAt="Server">Delete</button>

            <asp:Button id="SavePageButtonTop" OnClick="SaveTopic" CssClass="btn btn-primary btn-sm" Text="Save" RunAt="Server" />

          </div>
          <!-- /Editor Actions (Save, Delete) -->

          <!-- DisplayGroup Tabs Navigation -->
          <asp:ListView ID="DisplayGroupTabs" RunAt="Server">
            <LayoutTemplate>
              <ul class="nav nav-tabs" role="tablist">
                <asp:Placeholder ID="itemPlaceholder" RunAt="Server" />
              </ul>
            </LayoutTemplate>
            <ItemTemplate>
              <li<%# ((Container.DataItemIndex == 0)? " class=\"active\"" : "") %>>
                <a href="#<%# ((Master.IsModal)? "Modal_" : "") %>Group_<%# Eval("Value").ToString().Replace(" ", "_") %>" role="tab" data-toggle="tab"><%# Eval("Value") %></a>
              </li>
            </ItemTemplate>
          </asp:ListView>
          <!-- /DisplayGroup Tabs Navigation -->

        </div>

      </div>
    </div>
    <!-- /Toolbar (Topic Display Group Tabs, Action Buttons) -->

    <!-- Messages Area -->
    <div id="MessagesArea" class="row Messages-Area">
      <div class="col-md-12">

        <Ignia:ClientValidation SummaryClassName="Error Messaging" RunAt="Server" />

        <asp:Panel Visible=<%# Topic.DerivedTopic != null %> CssClass="alert alert-info alert-dismissable Derived-Topic" RunAt="Server">
          <!-- Inherited Topic Note -->
          <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
          This Topic inherits values from the Topic "<%# Topic.DerivedTopic != null? "<a class=\"alert-link\" href=\"/!Admin/Topics/Default.aspx?Path=" + Topic.DerivedTopic.UniqueKey + "\" target=\"_blank\" data-toggle=\"tooltip\" title=\"" + Topic.DerivedTopic.UniqueKey.Replace(":",": ") + "\">" + Topic.DerivedTopic.Key + "</a>" : "<i>Unavailable</i>" %>".
        </asp:Panel>

        <asp:Panel Visible=<%# !String.IsNullOrEmpty(NestedTopicAlert) %> CssClass="alert alert-info" role="alert" RunAt="Server">
          <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
          <%= NestedTopicAlert %>
        </asp:Panel>

        <asp:Panel Visible=<%# Topic.Parent.ContentType.Key.Equals("List") && !Master.IsModal  %> CssClass="alert alert-info" role="alert" RunAt="Server">
          <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
          You are currently editing a Nested Topic of <a href="Default.aspx?Path=<%# ((IsNew)? Topic.Parent.UniqueKey : ((Topic.Parent.Parent != null)? Topic.Parent.Parent.UniqueKey : "#")) %>" class="alert-link"><%# ((IsNew)? Topic.Parent.Title : ((Topic.Parent.Parent != null)? Topic.Parent.Parent.Title : "")) %></a>.
        </asp:Panel>

        <asp:Panel Visible=<%# DisableDelete %> CssClass="alert alert-warning" role="alert" RunAt="Server">
          <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
          You are attemtping to edit a Topic that is part of the OnTopic internal organizational structure and is not generally intended to be edited or deleted. Deletion of this Topic has been disabled in the editor. If you have reached this page unintentionally or are seeing this message due to an error, please notify development support with details about the issue.
        </asp:Panel>

      </div>
    </div>
    <!-- /Messages Area -->

    <!-- Primary Form Area (Form, Callouts) -->
    <div id="<%# ((Master.IsModal)? "Modal_" : "") %>FormArea" class="row Form-Area">

      <!-- Edit Form -->
      <div class="<%# ((Master.IsModal)? "col-md-12" : "col-md-9") %> Form-Body">

        <!-- DisplayGroup Tabs Content -->
        <div id="<%# ((Master.IsModal)? "Modal_" : "") %>DisplayGroupTabsContent" class="tab-content">
          <asp:Placeholder ID="DynamicForm" RunAt="Server" />
        </div>
        <!-- /DisplayGroup Tabs Content -->

      </div>
      <!-- /Edit Form -->

      <asp:PlaceHolder Visible=<%# !Master.IsModal %> RunAt="Server">
        <!-- Callout Area -->
        <div class="col-md-3 col-sm-hidden Callout-Area">
          <div id="FixedCallouts">

            <!-- Topic Information -->
            <asp:Panel CssClass="Callout Page-Info" Visible=<%# !IsNew %> RunAt="Server">
              <h3 class="h5">Topic Information</h4>
              <dl>
                <dt><i class="fa fa-cogs"></i> Content Type</dt>
                <dd><a href="/!Admin/Topics/Default.aspx?Path=<%# ContentType.UniqueKey %>"><%# Topic.ContentType.Key %></a></dd>
                <dt><i class="fa fa-database"></i> Topic ID</dt>
                <dd><a href="/Topic/<%# Topic.Id %>/"><%# Topic.Id %></a></dd>
                <dt><i class="fa fa-eye"></i> Current</dt>
                <dd><a href="<%= Topic.WebPath %>">View Page</a></dd>
              </dl>
            </asp:Panel>
            <!-- /Topic Information -->

          </div>
        </div>
        <!-- /Callout Area -->
      </asp:PlaceHolder>

    </div>
    <!-- /Primary Form Area (Form, Callouts) -->

  </div>
  <!-- /Editor Area -->

</asp:Content>

<asp:Content ContentPlaceHolderID="PageEnd" RunAt="Server">
  <div id="EditorModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-header">
        <h1 id="ModalTitle" class="h3 Page-Title"><!-- determined by modal open script caller --></h1>
      </div>
      <div class="modal-content">
        <iframe id="EditorFrame" src="" width="100%" marginheight="0" frameborder="0"><!-- iframe source determined by modal open script caller --></iframe>
      </div>
    </div>
  </div>


  <div id="EditorModalTest" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-header">
        <h1 id="ModalTitleTest" class="h3 Page-Title"><!-- determined by modal open script caller --></h1>
      </div>
      <div class="modal-content">
        <iframe id="EditorFrameTest" src="" width="100%" marginheight="0" frameborder="0"><!-- iframe source determined by modal open script caller --></iframe>
      </div>
    </div>
  </div>

</asp:Content>

<asp:Content ContentPlaceHolderId="PageScripts" RunAt="Server">

  <script src="Common/Scripts/Vendor/PaperCut/jQuery.are-you-sure.js"></script>
  <asp:PlaceHolder Visible=<%# !Master.IsModal %> RunAt="Server">
    <script src="Common/Scripts/Window.Primary.Functions.js"></script>
  </asp:PlaceHolder>
  <script src="Common/Scripts/Common.Functions.js"></script>
  <script>

  <asp:PlaceHolder Visible=<%# IsNew %> RunAt="Server">
    $(function() {

      // Auto-fill handling for Topic Key based on Topic Title
      $('input[id*="Title_Field"]').keydown(function(e) {
        var source              = $(this);
        var target              = $('input[id*="Key_Field"]');
        source.originalValue    = source.val();
        if (target.val() === getKeyValue(source.originalValue)) {
          setTimeout(function() {
            target.val(getKeyValue(source.val()));
          }, 50);
        }
      });

    });

  </asp:PlaceHolder>

    // Provide a warning and confirmation when user chooses to delete a Topic
    function confirmDelete() {
      return confirm('Are you sure you want to delete the "<%# Topic.Title %>" topic? The topic and all descendants will be permanently deleted.');
    }

  </script>

</asp:Content>