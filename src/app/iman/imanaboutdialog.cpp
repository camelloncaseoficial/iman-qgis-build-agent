/***************************************************************************
    imanaboutdialog.cpp
    ---------------------
    IMAN Terra: "Sobre o IMAN Terra" (fatia 059, prototipo). Ver o .h.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "imanaboutdialog.h"
#include "moc_imanaboutdialog.cpp"

#include "iman_brand.h"
#include "qgis.h"
#include "qgsapplication.h"

#include <QCoreApplication>
#include <QDialogButtonBox>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHBoxLayout>
#include <QIcon>
#include <QLabel>
#include <QPushButton>
#include <QTextBrowser>
#include <QVBoxLayout>

namespace
{
  const QChar MIDDLE_DOT( 0x00B7 );

  QString color( const char *hex )
  {
    return QString::fromLatin1( hex );
  }

  //! "3.44.13", sem o nome da versao
  QString engineVersion()
  {
    const int version = Qgis::versionInt();
    return QStringLiteral( "%1.%2.%3" ).arg( version / 10000 ).arg( version / 100 % 100 ).arg( version % 100 );
  }
} // namespace

QString ImanAboutDialog::displayVersion()
{
  const QString version = QString::fromUtf8( IMAN_PRODUCT_VERSION );
  const QString commit = Qgis::devVersion();
  if ( commit.isEmpty() || commit == QLatin1String( "exported" ) )
    return version;
  return QStringLiteral( "%1 %2 %3" ).arg( version, QString( MIDDLE_DOT ), commit );
}

QString ImanAboutDialog::qgisCreditsText( bool footer )
{
  const QString product = QString::fromUtf8( IMAN_PRODUCT_NAME );
  const QStringList sentences {
    tr( "%1 is an independent desktop geospatial experience, powered by QGIS." ).arg( product ),
    tr( "QGIS is a free and open source geographic information system, developed by QGIS.ORG and contributors." ),
    tr( "This project is not an official QGIS product and is not endorsed by QGIS.ORG." ),
  };
  if ( footer )
    return tr( "powered by QGIS: %1" ).arg( sentences.join( QLatin1Char( ' ' ) ) );
  return sentences.join( QLatin1Char( '\n' ) );
}

QString ImanAboutDialog::noticesPath()
{
  return QDir::cleanPath( QDir( QgsApplication::prefixPath() ).absoluteFilePath( QStringLiteral( "../../THIRD_PARTY_NOTICES.md" ) ) );
}

ImanAboutDialog::ImanAboutDialog( QWidget *parent )
  : QDialog( parent )
{
  const QString product = QString::fromUtf8( IMAN_PRODUCT_NAME );
  setObjectName( QStringLiteral( "imanAboutDialog" ) );
  setWindowTitle( tr( "About %1" ).arg( product ) );
  setMinimumSize( 620, 560 );

  QVBoxLayout *root = new QVBoxLayout( this );
  root->setContentsMargins( 22, 22, 22, 18 );
  root->setSpacing( 14 );

  // cabecalho: simbolo, nome, subtitulo, versao com o commit, motor, Instituto
  QHBoxLayout *top = new QHBoxLayout();
  top->setSpacing( 16 );
  QLabel *symbol = new QLabel();
  symbol->setObjectName( QStringLiteral( "imanAboutSymbol" ) );
  symbol->setPixmap( QIcon( QStringLiteral( ":/images/icons/qgis_icon.svg" ) ).pixmap( 72, 72 ) );
  symbol->setFixedWidth( 78 );
  symbol->setAlignment( Qt::AlignTop | Qt::AlignHCenter );
  top->addWidget( symbol );

  QVBoxLayout *identity = new QVBoxLayout();
  identity->setSpacing( 4 );
  QLabel *name = new QLabel( product );
  name->setObjectName( QStringLiteral( "imanAboutName" ) );
  identity->addWidget( name );
  QLabel *subtitle = new QLabel( tr( "A customized geospatial experience, powered by QGIS." ) );
  subtitle->setObjectName( QStringLiteral( "imanAboutSubtitle" ) );
  identity->addWidget( subtitle );
  QLabel *version = new QLabel( QStringLiteral( "%1 %2 %3 %4" ).arg( tr( "Version %1" ).arg( displayVersion() ), QString( MIDDLE_DOT ), QString::fromUtf8( IMAN_ENGINE_LABEL ), engineVersion() ) );
  version->setObjectName( QStringLiteral( "imanAboutVersion" ) );
  version->setTextInteractionFlags( Qt::TextSelectableByMouse );
  identity->addSpacing( 4 );
  identity->addWidget( version );
  QLabel *organization = new QLabel( QStringLiteral( "%1\n%2" ).arg( QString::fromUtf8( IMAN_ORGANIZATION_NAME ), QString::fromUtf8( IMAN_ORGANIZATION_FULL_NAME ) ) );
  organization->setObjectName( QStringLiteral( "imanAboutOrganization" ) );
  organization->setWordWrap( true );
  identity->addSpacing( 2 );
  identity->addWidget( organization );
  top->addLayout( identity, 1 );
  root->addLayout( top );

  // creditos do QGIS (BL-1, BL-2)
  QLabel *credits = new QLabel( qgisCreditsText() );
  credits->setObjectName( QStringLiteral( "imanAboutCredits" ) );
  credits->setWordWrap( true );
  root->addWidget( credits );

  // licencas de terceiros: o THIRD_PARTY_NOTICES.md que o produto entrega
  QLabel *noticesTitle = new QLabel( tr( "Third-party licenses" ) );
  noticesTitle->setObjectName( QStringLiteral( "imanAboutNoticesTitle" ) );
  root->addWidget( noticesTitle );
  mNotices = new QTextBrowser();
  mNotices->setObjectName( QStringLiteral( "imanAboutNotices" ) );
  mNotices->setOpenExternalLinks( true );
  const QString path = noticesPath();
  QFile file( path );
  if ( file.open( QIODevice::ReadOnly ) )
  {
    mNotices->setMarkdown( QString::fromUtf8( file.readAll() ) );
    mNotices->setToolTip( QDir::toNativeSeparators( path ) );
  }
  else
  {
    mNotices->setPlainText( tr( "The THIRD_PARTY_NOTICES.md file was not found in this installation (%1). It is delivered in the product folder, next to LICENSE." ).arg( QDir::toNativeSeparators( path ) ) );
  }
  root->addWidget( mNotices, 1 );

  // botoes: "Sobre o QGIS" (o QgsAbout de sempre, com os creditos, a licenca e os colaboradores) e Fechar
  QDialogButtonBox *buttons = new QDialogButtonBox();
  QPushButton *aboutQgis = new QPushButton( QCoreApplication::translate( "QgsAbout", "About QGIS" ) );
  aboutQgis->setObjectName( QStringLiteral( "imanAboutQgisButton" ) );
  aboutQgis->setIcon( QgsApplication::getThemeIcon( QStringLiteral( "/mActionHelpAbout.svg" ) ) );
  aboutQgis->setDefault( true );
  buttons->addButton( aboutQgis, QDialogButtonBox::ActionRole );
  buttons->addButton( QDialogButtonBox::Close );
  connect( aboutQgis, &QPushButton::clicked, this, &ImanAboutDialog::aboutQgisRequested );
  connect( buttons, &QDialogButtonBox::rejected, this, &QDialog::reject );
  root->addWidget( buttons );

  // cores so da paleta do tema (iman_brand.h, do cabecalho do style.qss); raio 2px
  setStyleSheet( QStringLiteral(
                   "#imanAboutName { font-size: 20px; font-weight: 700; color: %1; }"
                   "#imanAboutSubtitle { font-size: 13px; color: %2; }"
                   "#imanAboutVersion, #imanAboutOrganization { font-size: 12px; color: %3; }"
                   "#imanAboutCredits { font-size: 12px; color: %2; background: %4; border: 1px solid %5; border-radius: 2px; padding: 12px 14px; }"
                   "#imanAboutNoticesTitle { font-size: 13px; font-weight: 600; color: %2; }" )
                   .arg( color( IMAN_COLOR_BRAND ), color( IMAN_COLOR_TEXT ), color( IMAN_COLOR_TEXT_MUTED ), color( IMAN_COLOR_PANEL_2 ), color( IMAN_COLOR_BORDER ) ) );
}
