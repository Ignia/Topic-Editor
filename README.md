# OnTopic Editor for Web Forms
The **OnTopic-Editor-WebForms** is the legacy implementation of the **OnTopic Editor** for Microsoft's **ASP.NET Web Forms** framework.

> _Important:_ This project is considered obsolete, and no longer supported by Ignia. It is provided exclusively for reference. Existing implementations and new customers should upgrade to **[OnTopic-Editor-AspNetCore](https://github.com/OnTopicCMS/OnTopic-Editor-AspNetCore)**, which is built on Microsoft's **ASP.NET Core 3.1**.

## Installation


### Dependencies
Unlike more recent versions of the editor, the Web Forms version does not incorporate package management for downloading client-side dependencies, nor is it itself distributed as a package. To install the application, the following must be done:

#### Scripts
Client-side scripts must be downloaded and placed in the appropriate `/OnTopic.Editor.Web/Common/Scripts/Vendor` folders:

* `/Bootstrap`: [Twitter Bootstrap](https://getbootstrap.com/docs/3.4/) 3.x
* `/ExtJs`: [Sencha ExtJS](https://www.sencha.com/products/extjs/) 3.x
* `/jQueryUI`: [jQuery UI](https://jqueryui.com/) 1+
* `/PaperCut`: [PaperCut's Are You Sure?](https://plugins.jquery.com/are-you-sure/) 1+
* `/TokenInput`: [James Smith's TokenInput](https://loopj.com/jquery-tokeninput/) 1.7
* `/TrentRichardson`: [Trent Richardson's jQuery Timepicker Addon](https://github.com/trentrichardson/jQuery-Timepicker-Addon) 1.6.x

#### Libraries
There are a few dependencies that were previously distributed as a loose collection of proprietary scripts that need to be placed in the `/OnTopic.Editor.Web.Host/Common/Global` folder. These can be provided by [Ignia](http://www.ignia.com) upon request.

* `/Common/Global/Client.Scripts/FormatPhone.js`
* `/Common/Global/Client.Scripts/ClientValidation.js`
* `/Common/Global/Controls/ClientValidation.ascx`
* `/Common/Global/CS.Functions/AddAttributeToFields.aspx`

### Host Site
Once all of the dependencies are procured, the contents of the `OnTopic.Editor.Web` folder should be copied to the appropriate location in your host site. By convention, Ignia has traditionally placed this in the `/!Admin/Topics` directory, but the location is not fixed.

#### Configuration
For a configuration example, see the [`OnTopic.Editor.Web.Host`](OnTopic.Editor.Web.Host) project. It includes the absolute bare minimum configuration required to host the editor. This includes:

* [`web.config`](OnTopic.Editor.Web.Host/Web.config)
  * `connectionString` named `OnTopic`
  * `pageBaseType` set to `TopicPage`
  * Reference to the `OnTopic` namespaces
  * Configuration of the **C#** compiler
  * Inclusion of the **.NET Standard 2.0** assembly
* [`packages.config`](OnTopic.Editor.Web.Host/packages.config)
  * Declaring **OnTopic** dependencies, such as `OnTopic`, `OnTopic.Web`, `OnTopic.Data.Sql`, &c.
* [`global.asax.cs`](OnTopic.Editor.Web.Host/global.asax.cs)
  *  Override `TopicFactory.TypeLookupService` with `WebFormsTopicLookupService`
  *  Configure the `TopicRepository.DataProvider`
  *  Ignore routes going to `{resource}.axd/{*pathInfo}`

#### Visual Studio
If you are trying to get the `OnTopic.Editor.Web.Host` site working in **Visual Studio**, you'll want to setup a virtual directory from `OnTopic.Editor.Web.Host` to `Ontopic.Editor.Web`. This can be done in your local copy of `.vs/config/applicationHost.config` by adding a `<virtualDirectory />` element to the corresponding `<site />`. For example:
```
<configuration>
  <system.applicationHost>
    <sites>
      <site name="OnTopic.Editor.Web.Host" id="3">
        <application path="/" applicationPool="Clr4IntegratedAppPool">
          <virtualDirectory path="/" physicalPath="C:\Code\OnTopic-Editor-WebForms\OnTopic.Editor.Web.Host" />
          <virtualDirectory path="/!Admin/Topics" physicalPath="C:\Code\OnTopic-Editor-WebForms\OnTopic.Editor.Web" />
        </application>
        <bindings>
          <binding protocol="http" bindingInformation="*:63857:localhost" />
        </bindings>
      </site>
    </sites>
  </system.applicationHost>
</configuration>
```

> _Note:_ The path does not need to be setup to `/!Admin/Topics`, though that's the convention Ignia has traditionally used for this version of the editor.