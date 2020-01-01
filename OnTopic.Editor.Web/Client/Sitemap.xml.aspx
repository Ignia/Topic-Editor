<%@ Page Language="C#" %>

<%@ OutputCache CacheProfile="Server" %>

<%@ Import nameSpace="Ignia.Topics" %>

<script runat="server">

/*===========================================================================================================================
| SITEMAP XML
|
| Author      Jeremy Caney, Ignia LLC (Jeremy.Caney@Ignia.com)
| Client      GoldSim
| Project     CMS
|
| Purpose     Writes topics from the site in a format compatible with Google Sitemap.
|
>============================================================================================================================
| Revisions   Date        Author              Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|             06.09.10    Jeremy Caney        Customized output for expectation of Google Sitemap.
\--------------------------------------------------------------------------------------------------------------------------*/

/*===========================================================================================================================
| PAGE VARIABLES
\--------------------------------------------------------------------------------------------------------------------------*/
  bool          _isFirstNode            = true;
  string[]      _excludeAttributes      = { "Body", "IsActive", "IsDisabled", "ParentID", "URL", "RelatedContent", "SortOrder" };

/*===========================================================================================================================
| PAGE INIT
\--------------------------------------------------------------------------------------------------------------------------*/
  void Page_Init(object sender, EventArgs e) {

  /*=========================================================================================================================
  | DEFINE CONTENT TYPE
  \------------------------------------------------------------------------------------------------------------------------*/
    Response.ContentType = "text/xml";

  /*=========================================================================================================================
  | DEFINE ROOT NODE
  \------------------------------------------------------------------------------------------------------------------------*/
    Topic topicRoot = TopicRepository.RootTopic;

  /*=========================================================================================================================
  | RECURSIVELY WRITE TOPICS
  \------------------------------------------------------------------------------------------------------------------------*/
    Response.Write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
    Response.Write("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">");

    foreach (Topic topic in topicRoot) {
      Response.Write(AddNodeToOutput(topic, 1));
      }

    Response.Write("</urlset>");
    }

/*===========================================================================================================================
| METHOD: ADD NODE TO OUTPUT
>============================================================================================================================
| Adds the passed node along with all the child nodes to the output
\--------------------------------------------------------------------------------------------------------------------------*/
  string AddNodeToOutput(Topic topic, int indentLevel) {

  /*=========================================================================================================================
  | SKIP DISABLED AND CONFIGURATION
  \------------------------------------------------------------------------------------------------------------------------*/
    if (topic.Attributes.GetValue("IsInactive") == "1" || topic.Attributes.GetValue("IsDisabled") == "1") return "";
    if (topic.GetUniqueKey().StartsWith("Root:Configuration")) return "";

  /*=========================================================================================================================
  | ESTABLISH INDENT
  \------------------------------------------------------------------------------------------------------------------------*/
    string output = "";
    string indent = "".PadLeft(indentLevel*2, ' ');

  /*=========================================================================================================================
  | OPEN NODE
  \------------------------------------------------------------------------------------------------------------------------*/
    output += indent + "\n<url>";
    output += indent + "\n  <loc>" + Server.HtmlEncode("http://www.GoldSim.com" + topic.GetWebPath()) + "</loc>";
    output += indent + "\n  <changefreq>monthly</changefreq>";
    output += indent + "\n  <priority>" + (1.0/indentLevel).ToString() + "</priority>";
    output += indent + "\n  <pagemap>";

  /*=========================================================================================================================
  | LOOP THROUGH ATTRIBUTES
  \------------------------------------------------------------------------------------------------------------------------*/
    output += indent + "\n    <DataObject type=\"" + topic.Attributes.GetValue("ContentType", "Page") + "\">";
    foreach (AttributeValue attribute in topic.Attributes) {
      if (Array.IndexOf(_excludeAttributes, attribute.Key) >= 0) continue;
      if (topic.Attributes[attribute.Key].Value.Length > 256) continue;
      output += indent + "\n      <Attribute name=\"" + attribute.Key + "\">" + AntiXss.XmlEncode((string)topic.Attributes[attribute.Key].Value) + "</Attribute>";
      }
    output += indent + "\n    </DataObject>";

  /*=========================================================================================================================
  | LOOP THROUGH RELATIONSHIPS
  \------------------------------------------------------------------------------------------------------------------------*/
    foreach (Topic relationship in topic.Relationships) {
      output += indent + "\n    <DataObject type=\"" + relationship.Key + "\">";
      foreach (Topic relatedTopic in topic.Relationships[relationship.Key]) {
        output += indent + "\n      <Attribute name=\"TopicKey\">" + relatedTopic.GetUniqueKey().Replace("Root:", "") + "</Attribute>";
        }
      output += indent + "\n    </DataObject>";
      }

  /*=========================================================================================================================
  | CLOSE NODE
  \------------------------------------------------------------------------------------------------------------------------*/
    output += indent + "\n  </pagemap>";
    output += indent + "\n</url>";

  /*=========================================================================================================================
  | LOOP THROUGH CHILDREN
  \------------------------------------------------------------------------------------------------------------------------*/
    foreach (Topic childNode in topic) {
      output += AddNodeToOutput(childNode, indentLevel+1);
      }

  /*=========================================================================================================================
  | RETURN DATA
  \------------------------------------------------------------------------------------------------------------------------*/
    return output;

    }

</script>

