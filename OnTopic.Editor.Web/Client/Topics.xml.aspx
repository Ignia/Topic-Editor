<%@ Page Language="C#" %>

<%@ Import nameSpace="OnTopic" %>

<script runat="server">

/*=========================================================================================================================
| TOPICS BRIDGE XML
|
| Author:    Casey Margell, Ignia LLC (casey.margell@ignia.com)
| Client:    Microsoft
| Project:   AdCenter
|
| Purpose:   The Topics Bridge generates xml for the nodes in the topics system.
|
>=========================================================================================================================
| Revisions  Date        Author             Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|            10.03.06    Casey Margell      Created initial template based on resource editor bridge
|            07.21.09    Jeremy Caney       Customized output for expectation of dhtmlXTree.
\------------------------------------------------------------------------------------------------------------------------*/

/*===========================================================================================================================
| PAGE VARIABLES
\--------------------------------------------------------------------------------------------------------------------------*/
  bool         _isFirstNode    = true;

/*===========================================================================================================================
| PAGE INIT
\--------------------------------------------------------------------------------------------------------------------------*/
  void Page_Init(object sender, EventArgs e) {

    Response.ContentType = "text/xml";

  /*-----------------------------------------------------------------------------------------------------------------------
  | Get the desired nameSpace from the querystring and then grab the root topic for the nameSpace.
  \----------------------------------------------------------------------------------------------------------------------*/
    string nameSpace = Request.QueryString["nameSpace"];
    bool   showRoot  = (Request.QueryString["ShowRoot"]?? "true").ToLower().Equals("true");

    Topic topicRoot = null;

    if (String.IsNullOrEmpty(nameSpace)) {
      topicRoot = TopicRepository.RootTopic;
      }
    else {
    //topicRoot = TopicRepository.RootTopic[nameSpace];
      }

  //if we weren't able to get a topic root successfully return;
    if (topicRoot == null) return;

  /*=========================================================================================================================
  | Generate the output the nodes recursively.
  \------------------------------------------------------------------------------------------------------------------------*/
    Response.Write("<tree id=\"0\">");
    if (showRoot) {
      Response.Write(AddNodeToOutput(topicRoot, 1));
      }
    else {
      foreach (Topic topic in topicRoot.Children) {
        Response.Write(AddNodeToOutput(topic, 1));
        }
      }
    Response.Write("</tree>");
    }

/*===========================================================================================================================
| METHOD: ADD NODE TO OUTPUT
>============================================================================================================================
| Adds the passed node along with all the child nodes to the output
\--------------------------------------------------------------------------------------------------------------------------*/
  string AddNodeToOutput(Topic topic, int indentLevel) {

    string output = "";
    string indent = "".PadLeft(indentLevel*2, ' ');

    string initializer = "";
    if (_isFirstNode) {
      initializer = "open=\"1\" call=\"1\" select=\"1\"";
      _isFirstNode = false;
      }

    output += indent + "<item id=\"" + topic.Id + "\" text=\"" + HttpUtility.HtmlAttributeEncode(topic.Key) + "\" " + initializer + ">\n";

    foreach (Topic childNode in topic.Children) {
      output += AddNodeToOutput(childNode, indentLevel+1);
      }

    output += indent + "</item>\n";
    return output;
    }

</script>
