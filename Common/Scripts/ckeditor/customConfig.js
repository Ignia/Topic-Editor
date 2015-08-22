/*
Copyright (c) 2003-2010, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config ) {
//Define changes to default configuration here. For example:
//config.language = 'fr';
//config.uiColor = '#AADC6E';
  config.removePlugins          = 'autosave';
  config.allowedContent         = true;
  config.baseHref               = '/';
//config.height                 = '515px';
//config.resize_maxHeight       = '800';
  config.resize_maxWidth        = '800';
  config.contentsCss            = '/Common/Styles/CKEditor.css';
  config.toolbar                = 'OnTopic';
  config.toolbarCanCollapse     = true;
  config.toolbar_Full           = [
    ['Source','-','Save','NewPage','Preview','-','Templates'],
    ['Cut','Copy','Paste','PasteText','PasteFromWord','-','Print', 'SpellChecker', 'Scayt'],
    ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
    ['Form', 'Checkbox', 'Radio', 'TextField', 'Textarea', 'Select', 'Button', 'ImageButton', 'HiddenField'],
    '/',
    ['Bold','Italic','Underline','Strike','-','Subscript','Superscript'],
    ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote','CreateDiv'],
    ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
    ['Link','Unlink','Anchor'],
    ['Image','Flash','Table','HorizontalRule','Smiley','SpecialChar','PageBreak'],
    '/',
    ['Styles','Format','Font','FontSize'],
    ['TextColor','BGColor'],
    ['Maximize', 'ShowBlocks','-','About']
    ];
  config.toolbar_Basic          = [
    ['Bold', 'Italic', '-', 'NumberedList', 'BulletedList', '-', 'Link', 'Unlink','-','About']
    ];
  config.toolbar_OnTopic        = [
    ['Preview','Source','Undo','Redo','ShowBlocks','RemoveFormat'],
    ['Bold','Italic','Cut','Copy','Paste','PasteText','Scayt'],
    ['Styles'], //,'Format'
    '/',
    ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock','Outdent','Indent'],
    ['NumberedList','BulletedList','Link','Unlink','Anchor'],
    ['CreateDiv','Image','Table','HorizontalRule','SpecialChar'],
    ['Find','Replace','SelectAll','Maximize']
    ];
//Set font names
  config.font_names             =
    'Tahoma/Tahoma, Arial/Arial, sans-serif;'           +
    'Times New Roman/Times New Roman, Times, serif;'    +
    'Verdana';
//Call external styles set definition for Styles dropdown menu
  config.stylesCombo_stylesSet  = 'OnTopicStyleSet:styles/OnTopic.stylesSet.js';
//Set classes for styles defined in styles set
  config.bodyClass              = 'CKEPanel';

  };
