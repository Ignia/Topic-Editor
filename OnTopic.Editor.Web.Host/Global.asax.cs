/*==============================================================================================================================
| Author        Ignia, LLC
| Client        Ignia, LLC
| Project       OnTopicSample OnTopic Site
\=============================================================================================================================*/
using System;
using System.Configuration;
using System.Web.Routing;
using OnTopic.Data.Caching;
using OnTopic.Data.Sql;
using OnTopic.Web;

namespace OnTopic.Editor.Web.Host {

  /*============================================================================================================================
  | CLASS: GLOBAL
  \---------------------------------------------------------------------------------------------------------------------------*/
  /// <summary>
  ///   Provides default configuration for the application, including any special processing that needs to happen relative to
  ///   application events (such as <see cref="Application_Start"/> or <see cref="System.Web.HttpApplication.Error"/>.
  /// </summary>
  public class Global : System.Web.HttpApplication {

    /*==========================================================================================================================
    | EVENT: APPLICATION START
    >===========================================================================================================================
    | Runs once when the first page of your application is run for the first time by any user
    \-------------------------------------------------------------------------------------------------------------------------*/
    [Obsolete]
    protected void Application_Start(object sender, EventArgs e) {

      /*------------------------------------------------------------------------------------------------------------------------
      | ESTABLISH TOPIC LOOKUP SERVICE
      >-------------------------------------------------------------------------------------------------------------------------
      | This ensures that the TopicFactory is able to correctly create `ConfigurableAttributeDescriptor` topics as their
      | strongly typed class, which is necessary to provide access to members which parse and query the DefaultConfiguration
      | property.
      \-----------------------------------------------------------------------------------------------------------------------*/
      TopicFactory.TypeLookupService = new OnTopic.Editor.Web.WebFormsTopicLookupService();

      /*------------------------------------------------------------------------------------------------------------------------
      | CONFIGURE REPOSITORY
      \-----------------------------------------------------------------------------------------------------------------------*/
      var connectionString      = ConfigurationManager.ConnectionStrings["OnTopic"].ConnectionString;
      var sqlTopicRepository    = new SqlTopicRepository(connectionString);
      var topicRepository       = new CachedTopicRepository(sqlTopicRepository);

      TopicRepository.DataProvider = topicRepository;

      /*------------------------------------------------------------------------------------------------------------------------
      | REGISTER ROUTES
      \-----------------------------------------------------------------------------------------------------------------------*/
      RouteTable.Routes.Ignore("{resource}.axd/{*pathInfo}");

    }

  } //Class
} //Namespace