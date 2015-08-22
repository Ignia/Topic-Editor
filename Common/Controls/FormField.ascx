<%@ Control Language="C#" CodeFile="FormField.ascx.cs" Inherits="IgniaFormField" %>

  <asp:TextBox                     ID   = "Field"
    TextMode                            = "<%# TextMode %>"
    Label                               = "<%# GetLabel() %>"
    OnKeyUp                             = "<%# OnKeyUp %>"
    Style                               = "<%# FormatWidth(FieldSize, FieldHeight) %>"
    MaxLength                           = "<%# MaxLength %>"
    Enabled                             = "<%# Enabled %>"
    placeholder                         = "<%# InheritedValue %>"
    RunAt                               = "Server"
    />
  <asp:RequiredFieldValidator
    ID                                  = "RequiredValidator"
    ControlToValidate                   = "Field"
    Enabled                             = "False"
    ValidationGroup                     = "<%# ValidationGroup %>"
    RunAt                               = "Server"
    />
  <asp:PlaceHolder ID="PHRequired" runAt="Server" />
