/***************************************************************************
    imanfont.cpp
    ---------------------
    IMAN Terra: a fonte da marca na interface inteira (fatia 067). Ver
    imanfont.h.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "imanfont.h"

#include "iman_brand.h"
#include "imanpalette.h"
#include "qgsmessagelog.h"

#include <QApplication>
#include <QDir>
#include <QFont>
#include <QFontDatabase>
#include <QList>
#include <QPair>
#include <QStringList>

bool ImanFont::apply( const QString &uiTheme )
{
  // com um tema de fabrica escolhido pelo usuario, a fonte do sistema fica: nada muda
  if ( !ImanPalette::isDefaultTheme( uiTheme ) )
    return false;

  const QString family = QString::fromUtf8( IMAN_FONT_FAMILY );
  const QString tag = QString::fromUtf8( IMAN_PRODUCT_NAME );
  // os arquivos vem do recurso compilado (imanfonts.qrc): a lista sai dele, nao e escrita aqui
  const QDir resources( QStringLiteral( ":/iman/fonts" ) );
  const QStringList files = resources.entryList( { QStringLiteral( "*.ttf" ) }, QDir::Files, QDir::Name );

  QList<int> ids;
  QStringList failed;
  bool familyFound = false;
  for ( const QString &file : files )
  {
    const int id = QFontDatabase::addApplicationFont( resources.filePath( file ) );
    if ( id < 0 )
    {
      failed << file;
      continue;
    }
    ids << id;
    if ( QFontDatabase::applicationFontFamilies( id ).contains( family ) )
      familyFound = true;
  }

  if ( files.isEmpty() || !failed.isEmpty() || !familyFound )
  {
    // registro incompleto: desfaz o que entrou e fica a fonte do sistema
    for ( const int id : std::as_const( ids ) )
      QFontDatabase::removeApplicationFont( id );
    QgsMessageLog::logMessage( QStringLiteral( "Fonte da marca (%1) nao registrada: %2 arquivo(s) no recurso, falha em [%3], familia %4; segue a fonte do sistema." )
                                 .arg( family )
                                 .arg( files.size() )
                                 .arg( failed.join( QStringLiteral( ", " ) ) )
                                 .arg( familyFound ? QStringLiteral( "encontrada" ) : QStringLiteral( "ausente" ) ),
                               tag, Qgis::MessageLevel::Warning );
    return false;
  }

  // as fontes por classe que o tema da plataforma deu (no Windows, menus, barra de status, titulos de painel, dicas e
  // caixas de mensagem em outra familia e outro tamanho): o QApplication::setFont sem classe as apaga, entao sao
  // guardadas antes e devolvidas depois so com a familia trocada, cada uma no tamanho dela (decisao do sponsor na
  // fatia 067). A lista e a do QApplicationPrivate::initializeWidgetFontHash do Qt 5.15.
  static const char *const PLATFORM_FONT_CLASSES[] = {
    "QMenu", "QMenuBar", "QMenuItem", "QMessageBox", "QLabel", "QTipLabel", "QStatusBar", "QMdiSubWindowTitleBar",
    "QDockWidgetTitle", "QPushButton", "QCheckBox", "QRadioButton", "QToolButton", "QAbstractItemView", "QListView",
    "QHeaderView", "QListBox", "QComboMenuItem", "QComboLineEdit", "QSmallFont", "QMiniFont"
  };
  const QFont appFont = QApplication::font();
  QList<QPair<const char *, QFont>> classFonts;
  for ( const char *className : PLATFORM_FONT_CLASSES )
  {
    const QFont classFont = QApplication::font( className );
    if ( classFont != appFont )
      classFonts << qMakePair( className, classFont );
  }

  // so a familia muda: o tamanho e o que a aplicacao ja tem (o do sistema), em pontos ou em pixels
  QFont font = appFont;
  const qreal pointSize = font.pointSizeF();
  const int pixelSize = font.pixelSize();
  font.setFamily( family );
  if ( pointSize > 0 )
    font.setPointSizeF( pointSize );
  else if ( pixelSize > 0 )
    font.setPixelSize( pixelSize );
  QApplication::setFont( font );
  for ( const QPair<const char *, QFont> &entry : std::as_const( classFonts ) )
  {
    QFont classFont = entry.second;
    classFont.setFamily( family );
    QApplication::setFont( classFont, entry.first );
  }
  return true;
}
