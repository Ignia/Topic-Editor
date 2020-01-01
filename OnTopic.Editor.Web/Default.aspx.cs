/*==============================================================================================================================
| Author        Jeremy Caney, Ignia LLC (Jeremy.Caney@Ignia.com)
| Client        Ignia, LLC
| Project       Topics Library
\=============================================================================================================================*/
using System;
using System.Security.Principal;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Services;
using System.Linq;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using Ignia.Topics;
using Ignia.Topics.Collections;
using Ignia.Topics.Web.Editor;
using Ignia.Topics.Web;

/*==============================================================================================================================
| CLASS: TOPICS EDITOR PAGE
\-----------------------------------------------------------------------------------------------------------------------------*/
public partial class TopicsEditorPage : TopicPage {

  /*============================================================================================================================
  | PRIVATE FIELDS
  \---------------------------------------------------------------------------------------------------------------------------*/
  private       ContentTypeDescriptor           _contentType            = null;
  private       List<Ignia.Topics.AttributeDescriptor>    _contentTypeAttributes  = null;

  /*============================================================================================================================
  | PUBLIC PROPERTIES
  \---------------------------------------------------------------------------------------------------------------------------*/
  public        Dictionary<string, string>      Groups                  = new Dictionary<string, string>();

  /*============================================================================================================================
  | PROPERTY: IS NEW
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Determines if the topic should be treated as a new topic.If so, the form will default to blank and, when saved, a new
  ///   topic will be created.
  /// </summary>
  public bool IsNew {
    get {
      return (Request.QueryString["Action"]?? "").Equals("Add");
    }
  }

  /*============================================================================================================================
  | PROPERTY: IS MODAL
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Determines whether the editor is in the modal view.
  /// </summary>
  public bool IsModal {
    get {
      if (Request.QueryString["Modal"] != null && Request.QueryString["Modal"].ToLower() == "true") {
        return true;
      }
      else {
        return false;
      }
    }
  }

  /*============================================================================================================================
  | PROPERTY: DISABLE DELETE
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Determines whether to disable the[Delete] button based on a Topic's DisableDelete Attribute or a set list of
  ///   ContentTypes.
  /// </summary>
  public bool DisableDelete {
    get {
      if (!IsNew && (this.Topic.Attributes.GetValue("DisableDelete").Equals("1") || this.Topic.Attributes.GetValue("ContentType", "") == "List")) {
        return true;
      }
      else {
        return false;
      }
    }
  }

  /*============================================================================================================================
  | PROPERTY: NESTED TOPIC ALERT
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Builds and returns alert contents for when a nested topic has been saved or deleted; applies only to nested topics not
  ///   edited within the modal.
  /// </summary>
  public string NestedTopicAlert {
    get {
      string alertContents      = null;

      /*------------------------------------------------------------------------------------------------------------------------
      | Build alert base on whether the Action is "Saved" or "Deleted"
      \-----------------------------------------------------------------------------------------------------------------------*/
      if (Request.QueryString["Action"] != null) {
        string action           = Request.QueryString["Action"].ToString().ToLower();

        // Set saved topic alert information
        if (action.Equals("saved") && Request.QueryString["TopicID"] != null) {
          int savedTopicId;
          if (Int32.TryParse(Request.QueryString["TopicID"].ToString(), out savedTopicId)) {
            Topic savedTopic    = TopicRepository.DataProvider.Load(savedTopicId);
            if (savedTopic != null) {
              alertContents     = "<em>" + savedTopic.Parent.Title
                                + ": <a href=\"Default.aspx?Path=" + savedTopic.GetUniqueKey() + "\" class=\"alert-link\">"
                                + savedTopic.Title
                                + "</a></em> has been saved.";
            }
          }
          else {
            alertContents       = "has been saved.";
          }
        }

        // Set deleted topic alert information
        else if (action.Equals("deleted") && Request.QueryString["DeletedTopic"] != null && Request.QueryString["DeletedFrom"] != null) {
          alertContents         = "<em>" + Request.QueryString["DeletedFrom"].ToString()
                                + ": " + Request.QueryString["DeletedTopic"].ToString()
                                + "</em> was deleted.";
        }

      }

      /*------------------------------------------------------------------------------------------------------------------------
      | Return alert information, if available
      \-----------------------------------------------------------------------------------------------------------------------*/
      if (!String.IsNullOrEmpty(alertContents)) {
        return "Nested Topic " + alertContents;
      }
      else {
        return null;
      }

    }
  }

  /*============================================================================================================================
  | PROPERTY: CONTENT TYPE
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Identifies the ContentType topic based on the QueryString(for new topics) or the ContentType attribute of the current
  ///   this.Topic.
  /// </summary>
  public ContentTypeDescriptor ContentType {
    get {

      /*------------------------------------------------------------------------------------------------------------------------
      | Get cached instance
      \-----------------------------------------------------------------------------------------------------------------------*/
      if (_contentType != null) return _contentType;

      /*------------------------------------------------------------------------------------------------------------------------
      | Set identifier
      \-----------------------------------------------------------------------------------------------------------------------*/
      string contentType        = null;

      /*------------------------------------------------------------------------------------------------------------------------
      | Look up existing/current Topic Content Type
      \-----------------------------------------------------------------------------------------------------------------------*/
      if (!IsNew && this.Topic != null && !String.IsNullOrEmpty(this.Topic.ContentType)) {
        contentType             = this.Topic.ContentType;
      }

      /*------------------------------------------------------------------------------------------------------------------------
      | Look up querystring value if Topic is new
      \-----------------------------------------------------------------------------------------------------------------------*/
      else if (!String.IsNullOrEmpty((string)Request.QueryString["ContentType"])) {
        contentType             = Request.QueryString["ContentType"].ToString();
      }

      /*------------------------------------------------------------------------------------------------------------------------
      | Look up ContentType Topic
      \-----------------------------------------------------------------------------------------------------------------------*/
      if (contentType == null || TopicRepository.ContentTypes[contentType] == null) {
        throw new InvalidOperationException("The ContentType '" + contentType + "' could not be found in the TopicRepository.ContentTypes collection, which contains " + TopicRepository.ContentTypes.Count + " values.");
      }
      else {
        _contentType            = TopicRepository.ContentTypes[contentType];
      }

      /*------------------------------------------------------------------------------------------------------------------------
      | Return
      \-----------------------------------------------------------------------------------------------------------------------*/
      return _contentType;

    }
  }

  /*============================================================================================================================
  | CONTENT TYPE ATTRIBUTES
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Identifies the Attributes topic(s) for the ContentType topic based on the current ContentType.
  /// </summary>
  /// <remarks>
  ///   Automatically crawls up the ContentType hierarchy to add any Attributes inherited from parent ContentTypes; this
  ///   allows ContentTypes to be nested, thus deriving properties from their parents.
  /// </remarks>
  public List<Ignia.Topics.AttributeDescriptor> ContentTypeAttributes {
    get {

      /*------------------------------------------------------------------------------------------------------------------------
      | Get cached instance
      \-----------------------------------------------------------------------------------------------------------------------*/
      if (_contentTypeAttributes != null) return _contentTypeAttributes;

      /*------------------------------------------------------------------------------------------------------------------------
      | Look up Content Type Topic Attributes
      \-----------------------------------------------------------------------------------------------------------------------*/
      _contentTypeAttributes    = new List<Ignia.Topics.AttributeDescriptor>();

      if (ContentType != null) {

        // Get Attributes
        _contentTypeAttributes  = ContentType.AttributeDescriptors.ToList();

        // Set Order
        _contentTypeAttributes  = _contentTypeAttributes
                                  .OrderBy(contentTypeAttribute => contentTypeAttribute.DisplayGroup)
                                  .ThenBy(contentTypeAttribute => Int32.Parse(contentTypeAttribute.Attributes.GetValue("SortOrder", "25")))
                                  .ThenBy(contentTypeAttribute => contentTypeAttribute.Title)
                                  .ToList();
      }

      /*------------------------------------------------------------------------------------------------------------------------
      | Return
      \-----------------------------------------------------------------------------------------------------------------------*/
      return _contentTypeAttributes;

    }
  }

  /*============================================================================================================================
  | PAGE INIT
  \---------------------------------------------------------------------------------------------------------------------------*/
  void Page_Init(Object Src, EventArgs E) {

    /*--------------------------------------------------------------------------------------------------------------------------
    | Disable caching
    \-------------------------------------------------------------------------------------------------------------------------*/
    Response.Cache.SetCacheability(HttpCacheability.NoCache);

    /*--------------------------------------------------------------------------------------------------------------------------
    | Set default submit buttom to Save rather than Delete
    \-------------------------------------------------------------------------------------------------------------------------*/
    Page.Form.DefaultButton     = SavePageButtonTop.UniqueID;

    /*--------------------------------------------------------------------------------------------------------------------------
    | Set available Content Types
    \-------------------------------------------------------------------------------------------------------------------------*/
    if (ContentType != null && ContentType.Relationships.Contains("ContentTypes")) {
      TopicLookupControl.Topics = ContentType.Relationships["ContentTypes"];
    }

    /*-------------------------------------------------------------------------------------------------------------------------
    | Bind Versions list
    \------------------------------------------------------------------------------------------------------------------------*/
    BindVersionsList();

    /*--------------------------------------------------------------------------------------------------------------------------
    | ENSURE DATA BINDING
    \-------------------------------------------------------------------------------------------------------------------------*/
    // ###NOTE JJC100213: Data Binding must be performed in Page_Init in order for the dropdown lists to retain their selected
    // values. If it is called later (e.g, in Page_Load), either initially, or in duplicate, then the SelectedValue of the
    // controls will be reset.
    Page.DataBind();

  }

  /*============================================================================================================================
  | PAGE LOAD
  \---------------------------------------------------------------------------------------------------------------------------*/
  void Page_Load(Object Src, EventArgs E) {

    /*--------------------------------------------------------------------------------------------------------------------------
    | Populate form based on current Topic's Attributes
    \-------------------------------------------------------------------------------------------------------------------------*/
    AddAttributesToPage();

    /*-------------------------------------------------------------------------------------------------------------------------
    | Set Key field validator properties
    \------------------------------------------------------------------------------------------------------------------------*/
    /*
    CustomValidator keyFieldValidator   = FindControl("KeyFieldValidator") as CustomValidator;
    if (keyFieldValidator != null) {
      Response.Write("keyFieldValidator? " + keyFieldValidator.ClientID + "<br/>");
      }
    IEditControl control                = (IEditControl)DynamicForm.FindControl("Key");
    Response.Write("Key control? " + ((control != null)? control.ID : "Key field control is null") + "<br/>");
    KeyFieldValidator.ControlToValidate = "BodyArea$ContentArea$ContentContainer$Content$Key$Field";
    KeyFieldValidator.DataBind();
    */

  }

  /*============================================================================================================================
  | METHOD: ADD ATTRIBUTES TO PAGE
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Look up the Attributes based on the ContentType and dynamically add their corresponding IEditControl User Controls to
  ///   the page, followed by setting of properties (such as Value, IsRequired, etc).
  /// </summary>
  /// <remarks>
  ///   This is the primary "engine" of the Topics Editor and is responsible for drawing the form and setting the values.
  /// </remarks>
  public void AddAttributesToPage() {

    string lastGroup            = "";
    Panel groupContainer        = new Panel();
    Panel groupLabel            = null; // new Panel();

    /*--------------------------------------------------------------------------------------------------------------------------
    | Loop through Attributes
    \-------------------------------------------------------------------------------------------------------------------------*/
    // Attributes are drawn based on the defined ContentType's Attributes, as opposed to the Attributes found in the current
    // Topic. As a result, any "ad hoc" attributes added programmatically or orphaned from a previous ContentType setting will
    // not be displayed.
    foreach (Ignia.Topics.AttributeDescriptor contentTypeAttribute in ContentTypeAttributes) {

      /*------------------------------------------------------------------------------------------------------------------------
      | Ignore hidden Attributes
      \-----------------------------------------------------------------------------------------------------------------------*/
      // The IsHidden attribute of each Attribute determines whether or not that Attribute should be displayed in the editor.
      // Attributes may be set to IsHidden=1 if they are no longer needed, or if they're being managed by a separate process.
      // For instance, while ParentID is a valid Attribute for all ContentTypes, it is managed by the backend and doesn't need
      // to be displayed to editors.
      if (GetAttributeAsBool(contentTypeAttribute, "IsHidden", false)) continue;

      /*------------------------------------------------------------------------------------------------------------------------
      | Establish Display Group
      \-----------------------------------------------------------------------------------------------------------------------*/
      // The DisplayGroup attribute determines which tab the Attribute is rendered as part of. The Attributes are automatically
      // sorted based on DisplayGroup; as such, if an Attribute's DisplayGroup is different than that of the previous
      // DisplayGroup, that indicates that we need to draw a new Tab in order to render the Attribute in. These are written out
      // as divs (via the Panel class), which are subsequently interpreted by ExtJS as dynamic, client-side tabs.
      if (lastGroup != contentTypeAttribute.DisplayGroup) {
        groupLabel              = new Panel();
        groupLabel.CssClass     = "tab-pane";
        groupLabel.ID           = ((IsModal)? "Modal_" : "") + "Group_" + contentTypeAttribute.DisplayGroup.Replace(" ", "_");
        groupLabel.ClientIDMode = ClientIDMode.Static;
        lastGroup               = contentTypeAttribute.DisplayGroup;
        DynamicForm.Controls.Add(groupLabel);
        Groups.Add(groupLabel.ClientID, contentTypeAttribute.DisplayGroup);
      }

      /*------------------------------------------------------------------------------------------------------------------------
      | Create Attribute field
      \-----------------------------------------------------------------------------------------------------------------------*/
      // An Attribute field is composed of the label, description and the actual Attribute control. The label and description
      // are created by the Topic Editor independent of the Attribute Type. The actual Attribute control is injected into the
      // page using the Page.ParseControl() method, based on the convention that the Attribute control lives at the following
      // location: /Common/Controls/{Type}
      // -----------------------------------------------------------------------------------------------------------------------
      // ### NOTE JJC092213: Be aware that the Type name includes the ASCX extension. This allows its value to easily be bound
      // to a standard File Attribute (which lists files from a configured directory). As a result, however, the type must be
      // extracted from the Type attribute so that it can be used as the tag name in the control. This is because the tag name
      // cannot include punctuation (e.g., it cannot be <ITE:File.ascx />).
      Panel itemContainer               = new Panel();
      itemContainer.CssClass            = "Group-Item";

      Panel labelContainer              = new Panel();
      Label label                       = new Label();
      HyperLink description             = new HyperLink();

      string key                        = contentTypeAttribute.Key;
      string typeName                   = contentTypeAttribute.Attributes.GetValue("Type", "FormField.ascx");
      string tagName                    = typeName.Substring(0, typeName.LastIndexOf("."));

      string defaultConfiguration       = contentTypeAttribute.DefaultConfiguration;
      Control parseControl              = null;

      try {
        parseControl                    = Page.ParseControl("<%@ Register TagPrefix=\"ITE\" TagName=\"" + tagName + "\" Src=\"Common/Controls/" + typeName + "\" %><ITE:" + tagName + " " + defaultConfiguration + " ID=\"" + key + "\" ClientIDMode=\"Predictable\" RunAt=\"Server\" />");
      }
      catch(Exception ex) {
        throw new HttpParseException("Error parsing '" + tagName + "' for attribute '" + key + "'", ex);
      }

      // ParseControl returns a collection a control containing the collection of controls resulting from the parsing.
      // Therefore, the first control must be explicitly retrieved in order to properly cast it to the interface.
      IEditControl control              = (IEditControl)parseControl.Controls[0];

      /*------------------------------------------------------------------------------------------------------------------------
      | Set Attribute field values
      \-----------------------------------------------------------------------------------------------------------------------*/
      // Sets the values of the attributes based on the Attribute's attributes. For instance, the Label will be given the
      // Title, CSS classes will be defined, and the required properties of IEditControl will be set.
      labelContainer.CssClass           = "Content-Heading";

      label.Text                        = contentTypeAttribute.Title;
      label.AssociatedControlID         = contentTypeAttribute.Key;
      label.CssClass                    = "Content-Label";

      description.Text                  = "<span></span>";
      description.CssClass              = "glyphicon glyphicon-info-sign Content-Description";
      description.Attributes.Add("data-toggle", "tooltip");
      description.Attributes.Add("title", contentTypeAttribute.Description);

      control.Required                  = GetAttributeAsBool(contentTypeAttribute, "IsRequired") && this.Topic.DerivedTopic == null;
      control.Attribute                 = contentTypeAttribute;

      /*------------------------------------------------------------------------------------------------------------------------
      | Get inherited value
      \-----------------------------------------------------------------------------------------------------------------------*/
      // Topics can inherit values from other topics by including a Topic Pointer (via the TopicID attribute). Controls should
      // indicate to the user what the inherited value is so that users don't repeat data entry in these scenarios. For
      // instance, on a text box control (e.g., FormField Attribute) this might be done as a watermark (e.g., using the HTML5
      // placeholder attribute). It is up to each Attribute control, however, to determine if and how the InheritedValue is
      // rendered.
      // -----------------------------------------------------------------------------------------------------------------------
      // ### NOTE JJC092213: When calling Attributes.GetValue(), it is not possible to identify whether the value was inherited or
      // not. To mitigate this, the InheritedValue explicitly checks for a Topic Pointer and grabs the inherited value from the
      // referenced object. Typically, this isn't necessary as Attributes.GetValue() will automatically fallback to the Topic Pointer
      // if it exists.
      string inheritedValue             = null;

      if (this.Topic.DerivedTopic != null) {
        inheritedValue = this.Topic.DerivedTopic.Attributes.GetValue(key);
      }

      /*------------------------------------------------------------------------------------------------------------------------
      | Set values
      \-----------------------------------------------------------------------------------------------------------------------*/
      // If the user is editing an existing Topic, the value must be set based on the existing Topic value. This is handled
      // through the IEditControl's Value property, which the Attribute control will use to relay the value to the appropriate
      // format of the underlying control. For instance, if the Attribute control wraps a Checkbox control, then the value may
      // be parsed to set a .Checked property, whereas a DropDownList control may set a .SelectedValue property. By using the
      // Value interface, the underlying distinctions of each Attribute are handled by the Attribute control itself.
      // -----------------------------------------------------------------------------------------------------------------------
      // ### NOTE JJC092213: Relationships are specially handled by the editor itself due to the fact that they aren't actually
      // stored in the standard attribute format. E.g., in the SQL provider, for instance, they are stored in the
      // topics_Relationships table, instead of the standard topics_TopicAttributes and topics_Blob tables.
      // -----------------------------------------------------------------------------------------------------------------------
      // ### TODO KLT033015: Need to incorporate logic to look for TokenizedTopicList control as well (where
      // TokenizedTopicList.AsRelationship = true).
      if (this.Topic != null && !IsNew) {
        if (control is Relationships) {
          string relationships          = ",";
          string relationshipNamespace  = ((Relationships)control).Namespace;
          if (this.Topic.Relationships.Contains(relationshipNamespace)) {
            foreach (Topic relationship in this.Topic.Relationships[relationshipNamespace]) {
              relationships            += relationship.Id + ",";
            }
            control.Value               = relationships;
          }
        }
        else {
          control.Value                 = this.Topic.Attributes.GetValue(key, null, false, false);
          control.InheritedValue        = inheritedValue;
        }
      }

      /*------------------------------------------------------------------------------------------------------------------------
      | Add controls
      \-----------------------------------------------------------------------------------------------------------------------*/
      // Adds the label, description and Attribute control to the editor, to be rendered as part of the form.
      labelContainer.Controls.Add(label);
      labelContainer.Controls.Add(description);

      itemContainer.Controls.Add(labelContainer);
      itemContainer.Controls.Add((Control)control);

      if (groupLabel != null) {
        groupLabel.Controls.Add((Control)itemContainer);
      }

    }

    /*--------------------------------------------------------------------------------------------------------------------------
    | Bind tabs
    \-------------------------------------------------------------------------------------------------------------------------*/
    // Once all Display Groups have been defined, bind them to the navigation tabs.
    DisplayGroupTabs.DataSource         = Groups;
    DisplayGroupTabs.DataBind();

  }

  /*============================================================================================================================
  | METHOD: BIND VERSIONS LIST
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Sets the data source for the Versions dropdown list and binds the list.
  /// </summary>
  /// <remarks>
  ///   This method is only fired on page initialization, and in the case a Topic is rolled back to a previous Version.
  /// </remarks>
  protected void BindVersionsList() {

    Dictionary<string, string> dataSource       = new Dictionary<string, string>();

    /*--------------------------------------------------------------------------------------------------------------------------
    | Add Version to dropdown source if it is not already added
    \-------------------------------------------------------------------------------------------------------------------------*/
    foreach (DateTime version in this.Topic.VersionHistory) {
      string key                                = version.ToString();
      string value                              = version.ToString("yyyy-MM-dd HH:mm:ss.fff");
      if (!dataSource.ContainsKey(key)) {
        dataSource.Add(key, value);
      }
    }

    /*--------------------------------------------------------------------------------------------------------------------------
    | Populate dropdown
    \-------------------------------------------------------------------------------------------------------------------------*/
    if (!IsNew && Topic.VersionHistory.Count > 1) {
      VersionsListView.DataSource               = dataSource;
      VersionsListView.DataBind();
    }

  }

  /*============================================================================================================================
  | METHOD: GET ATTRIBUTE AS BOOL
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Returns true or false based on whether the Content Type Attribute is available and not empty.
  /// </summary>
  public bool GetAttributeAsBool (Topic topic, string name, bool defaultValue = false) {
    string value                = topic.Attributes.GetValue(name);
    if (String.IsNullOrEmpty(value)) return defaultValue;
    return value.ToLower().Equals("true") || value.Equals("1");
  }

  /*============================================================================================================================
  | METHOD: SET TOPIC VERSION
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Calls Topic.Rollback() with the selected version datetime to set the data to that version and re-save the Topic.
  /// </summary>
  protected void SetTopicVersion(object sender, EventArgs e) {

    LinkButton versionLink      = (LinkButton)(sender);
    string versionValue         = versionLink.CommandArgument;
    DateTime versionDateTime    = Convert.ToDateTime(versionValue);

    /*--------------------------------------------------------------------------------------------------------------------------
    | Initiate rollback
    \-------------------------------------------------------------------------------------------------------------------------*/
    TopicRepository.DataProvider.Rollback(this.Topic, versionDateTime);

    /*--------------------------------------------------------------------------------------------------------------------------
    | Repopulate dropdown
    \-------------------------------------------------------------------------------------------------------------------------*/
    BindVersionsList();
    Response.Redirect("?Path=" + this.Topic.GetUniqueKey());

  }

  /*============================================================================================================================
  | METHOD: DELETE TOPIC
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Fires when the user clicks the "Delete" button; deletes the current topic and any child attributes.
  /// </summary>
  public void DeleteTopic (Object Src, EventArgs E) {
    Topic topic                 = this.Topic.Parent;
    string deletedTopic         = this.Topic.Title;

    /*--------------------------------------------------------------------------------------------------------------------------
    | Lock the Topic repository before executing the delete
    \-------------------------------------------------------------------------------------------------------------------------*/
    lock (TopicRepository.RootTopic) {
      TopicRepository.DataProvider.Delete(this.Topic);
    }

    /*--------------------------------------------------------------------------------------------------------------------------
    | If the editor is in modal view, close the window; otherwise, redirect to the parent topic.
    \-------------------------------------------------------------------------------------------------------------------------*/
    if (IsModal) {
      StringBuilder closeOnDeleteScript         = new StringBuilder();
      closeOnDeleteScript.Append(@"<script>");
      closeOnDeleteScript.Append("   window.parent.closeModal()");
      closeOnDeleteScript.Append(@"</script>");
      ScriptManager.RegisterClientScriptBlock(this, this.GetType(), "CloseModalOnDelete", closeOnDeleteScript.ToString(), false);
    }
    else if (topic.Attributes.GetValue("ContentType", "") == "List") {
      Response.Redirect("?Path=" + topic.Parent.GetUniqueKey() + "&DeletedTopic=" + deletedTopic + "&DeletedFrom=" + topic.Title + "&Action=Deleted");
    }
    else {
      Response.Redirect("?Path=" + topic.GetUniqueKey());
    }

  }

  /*============================================================================================================================
  | METHOD: SAVE TOPIC
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Fires when the user clicks the "Save" button; saves modified topic attributes to the database store.
  /// </summary>
  public void SaveTopic (Object Src, EventArgs E) {

    /*--------------------------------------------------------------------------------------------------------------------------
    | Determine Topic
    \-------------------------------------------------------------------------------------------------------------------------*/
    Topic topic                 = this.Topic;
    if (IsNew) {
      string contentType        = Request.QueryString["ContentType"] ?? "Container";
      topic                     = TopicFactory.Create("Empty", contentType);
    }

    /*--------------------------------------------------------------------------------------------------------------------------
    | Look up and validate the associated Attribute; lock Topic repository prior to execution
    \-------------------------------------------------------------------------------------------------------------------------*/
    lock(TopicRepository.RootTopic) {

      // Process Content Type Attributes
      if (ContentType != null && ContentTypeAttributes.Count > 0) {

        foreach (Topic contentTypeAttribute in ContentTypeAttributes) {

          // Ignore invisible attributes
          if (GetAttributeAsBool(contentTypeAttribute, "IsHidden", false)) continue;

          IEditControl control  = (IEditControl)DynamicForm.FindControl(contentTypeAttribute.Key);

          // Debug
          if (control == null) {
            throw new NullReferenceException("Could not find expected control for '" + contentTypeAttribute.Key + "'.");
          }

          // Set Treeview control nodes to form field
          if (control is Relationships) {

            // Reset Relationships
            var relationshipNamespace   = ((Relationships)control).Namespace;
            if (topic.Relationships.Contains(relationshipNamespace)) {
              topic.Relationships.Clear();
            }

            List<string> relatedTopics  = control.Value.Split(',').ToList();
            foreach (string topicIdString in relatedTopics) {
              int topicIdInt;
              Topic relatedTopic        = null;
              bool isTopicId            = Int32.TryParse(topicIdString, out topicIdInt);
              if (isTopicId && topicIdInt > 0) {
                relatedTopic            = TopicRepository.DataProvider.Load(topicIdInt);
              }
              if (relatedTopic != null) {
                topic.Relationships.SetTopic(relationshipNamespace, relatedTopic);
              }
            }
            //topic.SetRelationship(((Relationships)control).Namespace, control.Value);
          }

          // Force Key change to go through property to ensure proper handling of renames.
          else if (contentTypeAttribute.Key == "Key") {
            string topicKey     = control.Value.TrimStart(' ').TrimEnd(' ').Replace(" ", "");
            topic.Key           = topicKey;
          }
          else if (String.IsNullOrEmpty(control.Value)) {
            if (topic.Attributes.Contains(contentTypeAttribute.Key)) {
              topic.Attributes.Remove(contentTypeAttribute.Key);
            }
          }
          else {
            if (!topic.Attributes.Contains(contentTypeAttribute.Key)) {
              topic.Attributes.Add(new AttributeValue(contentTypeAttribute.Key, control.Value));
            }
            else {
              topic.Attributes.SetValue(contentTypeAttribute.Key, control.Value);
            }
          }
        }

      }

      // Set ContentType Attribute based on page property
      if (ContentType != null) {
        if (!topic.Attributes.Contains("ContentType")) {
          topic.Attributes.Add(new AttributeValue("ContentType", ContentType.Key));
        }
        else {
          topic.Attributes.SetValue("ContentType", ContentType.Key);
        }
      }

      // Set Parent if Topic is new
      if (IsNew) {
        topic.Parent            = this.Topic;
      }

    }

    /*--------------------------------------------------------------------------------------------------------------------------
    | Execute save
    \-------------------------------------------------------------------------------------------------------------------------*/
    TopicRepository.DataProvider.Save(topic);

    /*--------------------------------------------------------------------------------------------------------------------------
    | If the editor is in modal view, close the window and return the topic's UniqueKey; otherwise, conditionally redirect to
    | the current topic.
    \-------------------------------------------------------------------------------------------------------------------------*/
    if (IsModal) {
      StringBuilder closeOnSaveScript   = new StringBuilder();
      closeOnSaveScript.Append(@"<script>");
      closeOnSaveScript.Append("   console.log('Saved: " + topic.GetUniqueKey() + "');");
      closeOnSaveScript.Append("   window.parent.closeModal()");
      closeOnSaveScript.Append(@"</script>");
      ScriptManager.RegisterClientScriptBlock(this, this.GetType(), "CloseModalOnSave", closeOnSaveScript.ToString(), false);
    }
    else if (topic.GetUniqueKey() != Request.QueryString["Path"]) {
      Response.Redirect("?Path=" + topic.GetUniqueKey() + "&Action=Saved");
    }
    else {
      Response.Redirect(Request.Url.PathAndQuery);
    }

  }

  /*============================================================================================================================
  | METHOD: VALIDATE TOPIC KEY
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Checks the Topic Key field value to ensure it does not match an existing Topic Key for a sibling Topic, and that it does
  ///   not contain non-alphanumeric characters; fires on server validation.
  /// </summary>
  /// <remarks>
  ///   Legacy / deprecated; ValidateKey is now part of the Ignia.Topics Topic class.
  /// </remarks>
  protected void ValidateTopicKey(object source, ServerValidateEventArgs args) {

    /*--------------------------------------------------------------------------------------------------------------------------
    | Test whether the value entered into the text box is even
    \-------------------------------------------------------------------------------------------------------------------------*/
    try {
      string keyValue = args.Value; //int i = int.Parse(args.Value);
      args.IsValid = true; //(keyValue.Length > 3);
    }
    catch(Exception ex) {
      args.IsValid = false;
    }

    /*--------------------------------------------------------------------------------------------------------------------------
    | Confirm that the Key is not already in the parent Topic before saving (and throwing an exception)
    \-------------------------------------------------------------------------------------------------------------------------*/
    /*
    foreach (Topic childTopic in topic.Parent) {
      if (childTopic.Key == topic.Key) {
        LiteralControl errorAlert       = ErrorAlert.Controls[0] as LiteralControl;
        errorAlert.Text                 = "<!-- <button type=\"button\" class=\"close\" data-dismiss=\"alert\">"
                                        + "<span aria-hidden=\"true\">&times;</span><span class=\"sr-only\">Close</span>"
                                        + "</button> -->"
                                        + "A Topic with the key '" + topic.Key + "' already exists under the parent Topic <i>"
                                        + topic.Parent.Key
                                        + "</i>. Please update this Topic's key to a new value.";
        ErrorAlert.Visible              = true;
        Response.End();
        }
      }
    */

  }

  /*============================================================================================================================
  | WEB METHOD: MOVE NODE
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   AJAX-parsable, querystring-configurable wrapper to the Ignia.Topics engine code that moves a node from one place in the
  ///   hierarchy to another. "true" if succeeded, Returns "false" if failure, as string values. The JS throws a generic
  ///   "failure" error on "false".
  /// </summary>
  [ WebMethod ]
  public static bool MoveNode(int topicId, int targetTopicId, int siblingId) {

    /*--------------------------------------------------------------------------------------------------------------------------
    | Retrieve the source and destination topics
    \-------------------------------------------------------------------------------------------------------------------------*/
    Topic topic                 = TopicRepository.DataProvider.Load(topicId);
    Topic target                = TopicRepository.DataProvider.Load(targetTopicId);

    /*--------------------------------------------------------------------------------------------------------------------------
    | Reset the source topic's Parent
    \-------------------------------------------------------------------------------------------------------------------------*/
    topic.Parent                = target;

    /*--------------------------------------------------------------------------------------------------------------------------
    | Move the topic and/or reorder it with its siblings; lock the Topic repository prior to execution
    \-------------------------------------------------------------------------------------------------------------------------*/
    lock (TopicRepository.RootTopic) {
      if (siblingId > 0) {
        Topic sibling           = TopicRepository.DataProvider.Load(siblingId);
        TopicRepository.DataProvider.Move(topic, target, sibling);
      }
      else {
        TopicRepository.DataProvider.Move(topic, target);
      }
    }

    /*--------------------------------------------------------------------------------------------------------------------------
    | Return
    \-------------------------------------------------------------------------------------------------------------------------*/
    return true;

  }

} // Class
