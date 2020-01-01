<%@ Control Language="C#" ClassName="File" Inherits="Ignia.Topics.Web.Editor.AttributeTypeControl" %>

<%@ Import Namespace="Ignia.Topics" %>
<%@ Import Namespace="System.IO" %>

<Script RunAt="Server">

/*===========================================================================================================================
| FILE
|
| Author:       Katherine Trunkey, Ignia LLC (Katherine.Trunkey@ignia.com)
| Client        Ignia
| Project       Topics Editor
|
| Purpose:      Displays a list of files given a path and, optionally, extension or filter.
|
>============================================================================================================================
| Revisions     Date            Author                  Comments
| - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
|               09.18.13        Katherine Trunkey       Created initial version.
|               10.17.13        Jeremy Caney            Updated to use new AttributeTypeControl base class.
\--------------------------------------------------------------------------------------------------------------------------*/

/*===========================================================================================================================
| PUBLIC MEMBERS
\--------------------------------------------------------------------------------------------------------------------------*/
  public        String                          CssClassRequired        = "FormField Required";
  public        String                          CssClassField           = "FormField";

/*===========================================================================================================================
| PRIVATE FIELDS
\--------------------------------------------------------------------------------------------------------------------------*/
  private       bool                            _isDataBound            = false;
  private       string                          _value                  = null;
  private       bool                            _required               = false;
  private       string                          _path                   = null;
  private       string                          _extension              = null;
  private       string                          _filter                 = null;
  private       bool                            _includeSubdirectories  = false;
  private       Dictionary<string, string>      _files                  = null;

/*===========================================================================================================================
| PROPERTY: PATH
>----------------------------------------------------------------------------------------------------------------------------
| Settable reference to the directory path in which to find available files.
\--------------------------------------------------------------------------------------------------------------------------*/
  public string Path {
    get {
      return _path;
      }
    set {
      _path = value;
      }
    }

/*===========================================================================================================================
| PROPERTY: EXTENSION
>----------------------------------------------------------------------------------------------------------------------------
| Settable reference to the file extension type by which to restrict the list of files.
\--------------------------------------------------------------------------------------------------------------------------*/
  public string Extension {
    get {
      return _extension;
      }
    set {
      _extension = value;
      }
    }

/*===========================================================================================================================
| PROPERTY: FILTER
>----------------------------------------------------------------------------------------------------------------------------
| Settable reference to the filter criteria by which to restrict the list of files.
\--------------------------------------------------------------------------------------------------------------------------*/
  public string Filter {
    get {
      return _filter;
      }
    set {
      _filter = value;
      }
    }

/*===========================================================================================================================
| PROPERTY: INCLUDE SUBDIRECTORIES
>----------------------------------------------------------------------------------------------------------------------------
| Settable reference to indicate whether to include only the specified directory or it and its subdirectories.
\--------------------------------------------------------------------------------------------------------------------------*/
  public bool IncludeSubdirectories {
    get {
      return _includeSubdirectories;
      }
    set {
      _includeSubdirectories = value;
      }
    }

/*===========================================================================================================================
| PROPERTY: VALUE
\--------------------------------------------------------------------------------------------------------------------------*/
  public override string Value {
    get {
      return FileList.SelectedValue;
      }
    set {
      _value = value;
      }
    }

/*===========================================================================================================================
| PROPERTY: REQUIRED
\--------------------------------------------------------------------------------------------------------------------------*/
  public override bool Required {
    get {
      return RequiredValidator.Enabled;
      }
    set {
      RequiredValidator.Enabled = value;
      if (value) {
        FileList.CssClass = CssClassRequired;
        }
      else {
        FileList.CssClass = CssClassField;
        }
      }
    }

/*===========================================================================================================================
| PROPERTY: FILES
>----------------------------------------------------------------------------------------------------------------------------
| Retrieves a collection of files in a directory, given the provided Path.
\--------------------------------------------------------------------------------------------------------------------------*/
  public Dictionary<string, string> Files {
    get {

      if (_files == null) {

      /*-----------------------------------------------------------------------------------------------------------------------
      | INSTANTIATE OBJECTS
      \----------------------------------------------------------------------------------------------------------------------*/
        Dictionary<string, string>        files           = new Dictionary<string, string>();
        string            searchPattern   = "*";
        SearchOption      searchOption    = SearchOption.TopDirectoryOnly;
        if (IncludeSubdirectories) {
          searchOption                    = SearchOption.AllDirectories;
          }

      /*-----------------------------------------------------------------------------------------------------------------------
      | FIND FILES
      \----------------------------------------------------------------------------------------------------------------------*/
        if (!String.IsNullOrEmpty(Path)) {

        /*---------------------------------------------------------------------------------------------------------------------
        | FILTER FILE LIST BASED ON EXTENSION
        \--------------------------------------------------------------------------------------------------------------------*/
          if (Extension != null) {
            searchPattern = searchPattern + "." + Extension;
            }

        /*---------------------------------------------------------------------------------------------------------------------
        | FILTER FILE LIST BASED ON FILTER CRITERIA
        \--------------------------------------------------------------------------------------------------------------------*/
          if (Filter != null) {
            searchPattern = Filter + searchPattern;
            }

        /*---------------------------------------------------------------------------------------------------------------------
        | GET ALL FILES
        \--------------------------------------------------------------------------------------------------------------------*/
          try {

            string[]    foundFiles              = Directory.GetFiles(@Server.MapPath(Path), searchPattern, searchOption);

            if (!String.IsNullOrEmpty(InheritedValue)) {
              string    inheritedValueKey       = InheritedValue.Replace("." + Extension, "");
              files.Add("", InheritedValue);
              }
            foreach (string foundFile in foundFiles) {
              string    fileName                = foundFile.Replace(Server.MapPath(Path), "");
              string    fileNameKey             = fileName.Replace("." + Extension, "");
              files.Add(fileName, fileNameKey);
              }

            }
          catch (Exception ex) {
            throw new Exception(ex.Message);
            }

        /*---------------------------------------------------------------------------------------------------------------------
        | ASSIGN RESULTS
        \--------------------------------------------------------------------------------------------------------------------*/
          _files = files;
          }

        }

    /*-----------------------------------------------------------------------------------------------------------------------
    | RETURN FILE LIST
    \----------------------------------------------------------------------------------------------------------------------*/
      return _files;
      }
    }

/*===========================================================================================================================
| PAGE INIT
>============================================================================================================================
| Provide handling for functions that must run prior to page load.  This includes dynamically constructed controls.
\--------------------------------------------------------------------------------------------------------------------------*/
  void Page_Init(Object Src, EventArgs E) {

  /*-------------------------------------------------------------------------------------------------------------------------
  | BIND EVENTS
    this.PreRender                     += new EventHandler(Page_PreRender);
    this.DataBinding                   += new EventHandler(Page_DataBinding);
  \------------------------------------------------------------------------------------------------------------------------*/

  /*-------------------------------------------------------------------------------------------------------------------------
  | DATA BIND CONTROL
  \------------------------------------------------------------------------------------------------------------------------*/
    this.DataBind();

  /*-------------------------------------------------------------------------------------------------------------------------
  | POPULATE DROPDOWNLIST
  \------------------------------------------------------------------------------------------------------------------------*/
    FileList.DataTextField              = "Value";
    FileList.DataValueField             = "Key";
    FileList.DataSource                 = Files;

  /*-------------------------------------------------------------------------------------------------------------------------
  | SET SELECTED INDEX
  \------------------------------------------------------------------------------------------------------------------------*/
    if (Request.QueryString["Type"] != null) {
      FileList.SelectedValue            = Request.QueryString["Type"].ToString();
      }
    else if (_value != null) {
      FileList.SelectedValue            = _value;
      }
    else if (!String.IsNullOrEmpty(InheritedValue)) {
      FileList.SelectedValue            = _value        = InheritedValue;
      }

    }

/*===========================================================================================================================
| PAGE LOAD
>============================================================================================================================
| Fires when page loads; has access to form and post back values.
\--------------------------------------------------------------------------------------------------------------------------*/
  void Page_Load(Object Src, EventArgs E) {

    }

/*===========================================================================================================================
| DATA BINDING
\--------------------------------------------------------------------------------------------------------------------------*/
  void Page_DataBinding(Object Src, EventArgs E) {

  /*-------------------------------------------------------------------------------------------------------------------------
  | PREVENT IMPLICIT DUPLICATE DATABINDING
  \------------------------------------------------------------------------------------------------------------------------*/
    _isDataBound                        = true;

    }

/*===========================================================================================================================
| PRE RENDER
\--------------------------------------------------------------------------------------------------------------------------*/
  void Page_PreRender(Object Src, EventArgs E) {

  /*-------------------------------------------------------------------------------------------------------------------------
  | ENSURE DATA BINDING
  \------------------------------------------------------------------------------------------------------------------------*/
    if (!_isDataBound) {
      this.DataBind();
      }

    }

</Script>

<div style="display: none;">
  _value: <%# _value %>
  <br/>InheritedValue: <%# InheritedValue %>
</div>

<asp:DropDownList
  ID                                    = "FileList"
  RunAt                                 = "Server"
  />

<asp:RequiredFieldValidator
  ID                                    = "RequiredValidator"
  ControlToValidate                     = "FileList"
  Enabled                               = "False"
  RunAt                                 = "Server"
  />
