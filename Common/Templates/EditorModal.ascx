<%@ Control Language="C#" ClassName="EditorModal" %>

<%@ Import Namespace="Ignia.Topics" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Web.UI" %>
<%@ Import Namespace="System.Collections.ObjectModel" %>

<Script RunAt="Server">

/*==============================================================================================================================
| EDITOR MODAL
|
| Author:       Katherine Trunkey, Ignia LLC (Katherine.Trunkey@ignia.com)
| Client        Ignia
| Project       Topics Editor
|
| Purpose:      Provides a modal markup template and functions associated with populating the modal contents.
|
>===============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               09.15.14        Katherine Trunkey       Created initial version.
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

/*==============================================================================================================================
| ATTRIBUTE NAME
>-------------------------------------------------------------------------------------------------------------------------------
| Settable reference to the Attribute Name (e.g., "ContentType") by which to filter the TopicSelection list. Both AttributeName
| and AttributeValue are required for use.
\-----------------------------------------------------------------------------------------------------------------------------*/
/*==============================================================================================================================
| GET TOPIC TITLE
>-------------------------------------------------------------------------------------------------------------------------------
| Retrieves the Topic's Title given the provided Topic Key string.
\-----------------------------------------------------------------------------------------------------------------------------*/
  private String GetTopicTitle(string topicKey) {
    Topic selectedTopic                 = Topics.Where(topic => topic.Key.Equals(topicKey)).FirstOrDefault();
    return (selectedTopic != null? selectedTopic.Title : "");
    }

</Script>
<div id="EditorModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-header">
      <h1 class="h3 Page-Title"><%# GetTopicTitle(DataSource.FirstOrDefault().Key) %></h1>
    </div>
    <div class="modal-content">
      <iframe id="EditorFrame_<%# DataSource.FirstOrDefault().Key %>" src="<%= DataSource.FirstOrDefault().Value %>&Modal=true" width="100%" marginheight="0" frameborder="0"></iframe>
    </div>
  </div>
</div>