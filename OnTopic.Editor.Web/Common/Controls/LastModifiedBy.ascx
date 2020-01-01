<%@ Control Language="C#" ClassName="LastModifiedBy" Inherits="OnTopic.Web.Editor.AttributeTypeControl" %>

<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="OnTopic" %>

<Script RunAt="Server">

/*==============================================================================================================================
| LAST MODIFIED BY FIELD
|
| Author        Katherine Trunkey, Ignia LLC (katherine.trunkeyignia.com)
| Client        Ignia, LLC
| Project       OnTopic
|
| Purpose       Implements a current editing user account field (e.g., DOMAIN\username) used for auditing purposes for the
|               OnTopic editor.
|
>===============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               09.15.14        Katherine Trunkey       Created initial version.
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| DECLARE PUBLIC FIELDS
>===============================================================================================================================
| Public fields will be exposed as properties to user control
\-----------------------------------------------------------------------------------------------------------------------------*/

/*==============================================================================================================================
| DECLARE PRIVATE VARIABLES
>===============================================================================================================================
| Declare variables that will have a page scope
\-----------------------------------------------------------------------------------------------------------------------------*/
  private       string          _value                  = null;

/*==============================================================================================================================
| PROPERTY: VALUE
\-----------------------------------------------------------------------------------------------------------------------------*/
  public override String Value {
    get {
      if (_value == null) {
        _value = HttpContext.Current.User.Identity.Name;
        }
      return _value;
      }
    set {
      _value = value;
      }
    }

/*==============================================================================================================================
| PAGE LOAD
>===============================================================================================================================
| Handle all requests for page load, including state control based on user input
\-----------------------------------------------------------------------------------------------------------------------------*/
  void Page_Load(Object Src, EventArgs E) {

  /*----------------------------------------------------------------------------------------------------------------------------
  | HANDLE DEFERRED VALUE SET
  \---------------------------------------------------------------------------------------------------------------------------*/
    if (_value != null) {
      Value                     = _value;
      }

    }

</Script>

<div class="Last-Modified"><%= _value?? Value %></div>