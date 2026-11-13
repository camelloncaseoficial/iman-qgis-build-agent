/***************************************************************************
    imanhomepage.cpp
    ---------------------
    IMAN Terra: pagina inicial da marca (fatia 059, prototipo). Ver o .h.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "imanhomepage.h"
#include "moc_imanhomepage.cpp"
#include "imanaboutdialog.h"

#include "iman_brand.h"
#include "qgisapp.h"
#include "qgis.h"
#include "qgsapplication.h"
#include "qgscoordinatereferencesystem.h"
#include "qgsfileutils.h"
#include "qgsfocuskeeper.h"
#include "qgsgui.h"
#include "qgsnative.h"
#include "qgsprojectlistitemdelegate.h"
#include "qgsprojectstorage.h"
#include "qgsprojectstorageregistry.h"
#include "qgssettings.h"
#include "qgstemplateprojectsmodel.h"
#include "qgswelcomepage.h"

#include <QAction>
#include <QDesktopServices>
#include <QDir>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QIcon>
#include <QKeyEvent>
#include <QLabel>
#include <QListView>
#include <QMenu>
#include <QMouseEvent>
#include <QPainter>
#include <QRegularExpression>
#include <QScrollArea>
#include <QTextDocument>
#include <QUrl>
#include <QVBoxLayout>

namespace
{
  // separador dos selos (ponto medio), fora do fonte como literal: o fonte fica ASCII
  const QChar MIDDLE_DOT( 0x00B7 );

  QString color( const char *hex )
  {
    return QString::fromLatin1( hex );
  }

  QLabel *sectionTitle( const QString &text )
  {
    QLabel *label = new QLabel( text );
    label->setObjectName( QStringLiteral( "imanHomeSectionTitle" ) );
    return label;
  }
} // namespace


//
// ImanHomeCard
//

ImanHomeCard::ImanHomeCard( const QString &iconPath, const QString &title, const QString &subtitle, QWidget *parent )
  : QFrame( parent )
{
  setObjectName( QStringLiteral( "imanHomeCard" ) );
  setCursor( Qt::PointingHandCursor );
  setFocusPolicy( Qt::StrongFocus );
  setAccessibleName( title );

  QVBoxLayout *layout = new QVBoxLayout( this );
  layout->setContentsMargins( 16, 16, 16, 16 );
  layout->setSpacing( 12 );

  QLabel *tile = new QLabel();
  tile->setObjectName( QStringLiteral( "imanHomeCardTile" ) );
  tile->setFixedSize( 42, 42 );
  tile->setAlignment( Qt::AlignCenter );
  tile->setPixmap( QgsApplication::getThemeIcon( iconPath ).pixmap( 24, 24 ) );
  layout->addWidget( tile );

  QLabel *titleLabel = new QLabel( title );
  titleLabel->setObjectName( QStringLiteral( "imanHomeCardTitle" ) );
  layout->addWidget( titleLabel );
  QLabel *subtitleLabel = new QLabel( subtitle );
  subtitleLabel->setObjectName( QStringLiteral( "imanHomeCardSubtitle" ) );
  layout->addWidget( subtitleLabel );
  layout->addStretch( 1 );

  for ( QLabel *label : { tile, titleLabel, subtitleLabel } )
    label->setAttribute( Qt::WA_TransparentForMouseEvents );
}

void ImanHomeCard::mouseReleaseEvent( QMouseEvent *event )
{
  if ( event->button() == Qt::LeftButton && rect().contains( event->pos() ) )
    emit clicked();
  QFrame::mouseReleaseEvent( event );
}

void ImanHomeCard::keyPressEvent( QKeyEvent *event )
{
  if ( event->key() == Qt::Key_Return || event->key() == Qt::Key_Enter || event->key() == Qt::Key_Space )
  {
    emit clicked();
    return;
  }
  QFrame::keyPressEvent( event );
}


//
// ImanProjectItemDelegate
//

ImanProjectItemDelegate::ImanProjectItemDelegate( bool showPath, QObject *parent )
  : QStyledItemDelegate( parent )
  , mShowPath( showPath )
{
}

void ImanProjectItemDelegate::paint( QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index ) const
{
  painter->save();
  painter->setRenderHint( QPainter::Antialiasing, true );

  const bool enabled = index.flags() & Qt::ItemIsEnabled;
  const bool hover = enabled && ( option.state & QStyle::State_MouseOver );
  const QRectF box = QRectF( option.rect ).adjusted( 0.5, 2.5, -0.5, -2.5 );
  if ( hover )
  {
    painter->setPen( QColor( IMAN_COLOR_BORDER ) );
    painter->setBrush( QColor( IMAN_COLOR_PANEL ) );
    painter->drawRoundedRect( box, 2, 2 );
  }

  const QString title = index.data( QgsProjectListItemDelegate::TitleRole ).toString();
  const bool pinned = index.data( QgsProjectListItemDelegate::PinRole ).toBool();
  const QString detail = mShowPath ? index.data( QgsProjectListItemDelegate::AnonymisedNativePathRole ).toString()
                                   : index.data( QgsProjectListItemDelegate::CrsRole ).toString();

  const QString titleColor = enabled ? color( IMAN_COLOR_TEXT ) : color( IMAN_COLOR_TEXT_FAINT );
  QTextDocument doc;
  doc.setDocumentMargin( 0 );
  doc.setHtml( QStringLiteral( "<div style='font-size:13px;font-weight:600;color:%1'>%2%3</div>"
                               "<div style='font-size:11px;color:%4'>%5</div>" )
                 .arg( titleColor, title.toHtmlEscaped(), pinned ? QStringLiteral( " <img src=\":/images/themes/default/pin.svg\" width=\"12\" height=\"12\">" ) : QString(), color( IMAN_COLOR_TEXT_FAINT ), detail.toHtmlEscaped() ) );
  doc.setTextWidth( option.rect.width() - 20 );
  painter->translate( option.rect.left() + 10, option.rect.top() + 8 );
  doc.drawContents( painter );
  painter->restore();
}

QSize ImanProjectItemDelegate::sizeHint( const QStyleOptionViewItem &option, const QModelIndex &index ) const
{
  Q_UNUSED( index )
  QFont titleFont = option.font;
  titleFont.setPixelSize( 13 );
  QFont detailFont = option.font;
  detailFont.setPixelSize( 11 );
  const int height = QFontMetrics( titleFont ).height() + QFontMetrics( detailFont ).height() + 18;
  return QSize( option.rect.width(), height );
}


//
// ImanHomePage
//

ImanHomePage::ImanHomePage( QgsWelcomePage *welcomePage, QWidget *parent )
  : QWidget( parent )
  , mWelcomePage( welcomePage )
{
  setObjectName( QStringLiteral( "imanHomePage" ) );

  QVBoxLayout *outer = new QVBoxLayout( this );
  outer->setContentsMargins( 0, 0, 0, 0 );
  QScrollArea *scroll = new QScrollArea();
  scroll->setObjectName( QStringLiteral( "imanHomeScroll" ) );
  scroll->setWidgetResizable( true );
  scroll->setFrameShape( QFrame::NoFrame );
  outer->addWidget( scroll );

  QWidget *page = new QWidget();
  page->setObjectName( QStringLiteral( "imanHomeContent" ) );
  scroll->setWidget( page );
  QVBoxLayout *layout = new QVBoxLayout( page );
  layout->setContentsMargins( 30, 28, 30, 26 );
  layout->setSpacing( 22 );

  // cabecalho: sobretitulo, titulo e subtitulo a esquerda; selos de versao e de SRC a direita
  QHBoxLayout *hero = new QHBoxLayout();
  QVBoxLayout *heroText = new QVBoxLayout();
  heroText->setSpacing( 6 );
  QLabel *eyebrow = new QLabel( tr( "TERRITORIAL INTELLIGENCE, CADASTRE AND REURB, CEARA" ) );
  eyebrow->setObjectName( QStringLiteral( "imanHomeEyebrow" ) );
  heroText->addWidget( eyebrow );
  QLabel *heading = new QLabel( tr( "Welcome to %1" ).arg( QString::fromUtf8( IMAN_PRODUCT_NAME ) ) );
  heading->setObjectName( QStringLiteral( "imanHomeHeading" ) );
  heroText->addWidget( heading );
  QLabel *subtitle = new QLabel( tr( "Land regularization, territorial cadastre and cartography in a single geospatial platform." ) );
  subtitle->setObjectName( QStringLiteral( "imanHomeSubtitle" ) );
  subtitle->setWordWrap( true );
  subtitle->setMaximumWidth( 620 );
  heroText->addWidget( subtitle );
  hero->addLayout( heroText, 1 );

  QVBoxLayout *badges = new QVBoxLayout();
  badges->setAlignment( Qt::AlignRight | Qt::AlignTop );
  badges->setSpacing( 8 );
  QLabel *versionBadge = new QLabel( tr( "version %1" ).arg( ImanAboutDialog::displayVersion() ) );
  versionBadge->setObjectName( QStringLiteral( "imanHomeVersionBadge" ) );
  versionBadge->setTextInteractionFlags( Qt::TextSelectableByMouse );
  badges->addWidget( versionBadge, 0, Qt::AlignRight );
  mCrsBadge = new QLabel();
  mCrsBadge->setObjectName( QStringLiteral( "imanHomeCrsBadge" ) );
  badges->addWidget( mCrsBadge, 0, Qt::AlignRight );
  hero->addLayout( badges, 0 );
  layout->addLayout( hero );

  // cartoes: as acoes que o QGIS ja tem, disparadas pelo nome do objeto
  QGridLayout *cards = new QGridLayout();
  cards->setSpacing( 14 );
  struct CardSpec
  {
      QString icon;
      QString title;
      QString subtitle;
      QString action;
  };
  const QList<CardSpec> specs {
    { QStringLiteral( "/mActionFileNew.svg" ), tr( "New project" ), tr( "Start from scratch" ), QStringLiteral( "mActionNewProject" ) },
    { QStringLiteral( "/mActionFileOpen.svg" ), tr( "Open project" ), tr( "Files .qgz / .qgs" ), QStringLiteral( "mActionOpenProject" ) },
    { QStringLiteral( "/mActionDataSourceManager.svg" ), tr( "Load data" ), tr( "Raster, vector, mesh" ), QStringLiteral( "mActionDataSourceManager" ) },
    { QStringLiteral( "/mActionNewLayout.svg" ), tr( "New layout" ), tr( "Print composition" ), QStringLiteral( "mActionNewPrintLayout" ) },
  };
  int column = 0;
  for ( const CardSpec &spec : specs )
  {
    ImanHomeCard *card = new ImanHomeCard( spec.icon, spec.title, spec.subtitle );
    card->setProperty( "imanAction", spec.action );
    const QString action = spec.action;
    connect( card, &ImanHomeCard::clicked, this, [action] { triggerAppAction( action ); } );
    cards->addWidget( card, 0, column++ );
  }
  layout->addLayout( cards );

  // projetos recentes: o modelo da QgsWelcomePage, com o estado vazio explicito
  layout->addWidget( sectionTitle( tr( "Recent projects" ) ) );
  mRecentProjectsView = new QListView();
  mRecentProjectsView->setObjectName( QStringLiteral( "imanHomeRecentProjects" ) );
  mRecentProjectsView->setSelectionMode( QAbstractItemView::NoSelection );
  mRecentProjectsView->setMouseTracking( true );
  mRecentProjectsView->setFrameShape( QFrame::NoFrame );
  mRecentProjectsView->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
  mRecentProjectsView->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
  mRecentProjectsView->setContextMenuPolicy( Qt::CustomContextMenu );
  mRecentProjectsView->setItemDelegate( new ImanProjectItemDelegate( true, mRecentProjectsView ) );
  mRecentProjectsView->viewport()->setCursor( Qt::PointingHandCursor );
  if ( mWelcomePage )
  {
    mRecentProjectsModel = mWelcomePage->recentProjectsModel();
    mRecentProjectsView->setModel( mRecentProjectsModel );
    connect( mRecentProjectsModel, &QAbstractItemModel::modelReset, this, &ImanHomePage::updateRecentProjects );
    connect( mRecentProjectsModel, &QAbstractItemModel::layoutChanged, this, &ImanHomePage::updateRecentProjects );
    connect( mRecentProjectsModel, &QAbstractItemModel::rowsInserted, this, &ImanHomePage::updateRecentProjects );
    connect( mRecentProjectsModel, &QAbstractItemModel::rowsRemoved, this, &ImanHomePage::updateRecentProjects );
    connect( mRecentProjectsModel, &QAbstractItemModel::dataChanged, this, &ImanHomePage::updateRecentProjects );
  }
  connect( mRecentProjectsView, &QListView::clicked, this, &ImanHomePage::recentProjectClicked );
  connect( mRecentProjectsView, &QListView::customContextMenuRequested, this, &ImanHomePage::showContextMenuForProjects );
  layout->addWidget( mRecentProjectsView );
  mRecentProjectsEmpty = new QLabel( tr( "No recent projects yet. Start with \"New project\" or open an existing project: the ones you use will show up here." ) );
  mRecentProjectsEmpty->setObjectName( QStringLiteral( "imanHomeEmpty" ) );
  mRecentProjectsEmpty->setWordWrap( true );
  layout->addWidget( mRecentProjectsEmpty );

  // modelos de projeto da pagina nativa (o sponsor decide no smoke se ficam)
  layout->addWidget( sectionTitle( tr( "Project templates" ) ) );
  mTemplateProjectsModel = new QgsTemplateProjectsModel( this );
  mTemplatesView = new QListView();
  mTemplatesView->setObjectName( QStringLiteral( "imanHomeTemplates" ) );
  mTemplatesView->setSelectionMode( QAbstractItemView::NoSelection );
  mTemplatesView->setMouseTracking( true );
  mTemplatesView->setFrameShape( QFrame::NoFrame );
  mTemplatesView->setVerticalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
  mTemplatesView->setHorizontalScrollBarPolicy( Qt::ScrollBarAlwaysOff );
  mTemplatesView->setItemDelegate( new ImanProjectItemDelegate( false, mTemplatesView ) );
  mTemplatesView->viewport()->setCursor( Qt::PointingHandCursor );
  mTemplatesView->setModel( mTemplateProjectsModel );
  connect( mTemplateProjectsModel, &QAbstractItemModel::rowsInserted, this, &ImanHomePage::updateTemplates );
  connect( mTemplateProjectsModel, &QAbstractItemModel::rowsRemoved, this, &ImanHomePage::updateTemplates );
  connect( mTemplateProjectsModel, &QAbstractItemModel::modelReset, this, &ImanHomePage::updateTemplates );
  connect( mTemplatesView, &QListView::clicked, this, &ImanHomePage::templateClicked );
  layout->addWidget( mTemplatesView );

  layout->addStretch( 1 );

  // creditos do QGIS (BL-1, BL-2)
  QFrame *divider = new QFrame();
  divider->setObjectName( QStringLiteral( "imanHomeDivider" ) );
  divider->setFrameShape( QFrame::NoFrame );
  divider->setFixedHeight( 1 );
  layout->addWidget( divider );
  QLabel *credits = new QLabel( ImanAboutDialog::qgisCreditsText( true ) );
  credits->setObjectName( QStringLiteral( "imanHomeCredits" ) );
  credits->setWordWrap( true );
  layout->addWidget( credits );

  // cores so da paleta do tema (iman_brand.h, do cabecalho do style.qss); raio 2px
  setStyleSheet( QStringLiteral(
                   "#imanHomeScroll, #imanHomeContent { background: %1; }"
                   "#imanHomeEyebrow { font-size: 11px; font-weight: 600; letter-spacing: 1.4px; color: %2; }"
                   "#imanHomeHeading { font-size: 26px; font-weight: 600; color: %3; }"
                   "#imanHomeSubtitle { font-size: 14px; color: %4; }"
                   "#imanHomeVersionBadge { font-size: 12px; color: %4; background: %5; border: 1px solid %6; border-radius: 2px; padding: 6px 11px; }"
                   "#imanHomeCrsBadge { font-size: 12px; color: %7; }"
                   "#imanHomeCard { background: %5; border: 1px solid %6; border-radius: 2px; }"
                   "#imanHomeCard:hover, #imanHomeCard:focus { border: 1px solid %2; }"
                   "#imanHomeCardTile { background: %8; border-radius: 2px; }"
                   "#imanHomeCardTitle { font-size: 14px; font-weight: 600; color: %3; }"
                   "#imanHomeCardSubtitle { font-size: 12px; color: %7; }"
                   "#imanHomeSectionTitle { font-size: 15px; font-weight: 600; color: %3; }"
                   "#imanHomeRecentProjects, #imanHomeTemplates { background: transparent; }"
                   "#imanHomeEmpty { font-size: 12px; color: %7; padding: 10px 0px; }"
                   "#imanHomeDivider { background: %6; }"
                   "#imanHomeCredits { font-size: 11px; color: %7; }" )
                   .arg( color( IMAN_COLOR_BG ), color( IMAN_COLOR_BRAND_2 ), color( IMAN_COLOR_TEXT ), color( IMAN_COLOR_TEXT_MUTED ), color( IMAN_COLOR_PANEL ), color( IMAN_COLOR_BORDER ), color( IMAN_COLOR_TEXT_FAINT ), color( IMAN_COLOR_ACTIVE_BG ) ) );

  updateCrsBadge();
  updateRecentProjects();
  updateTemplates();
}

void ImanHomePage::showEvent( QShowEvent *event )
{
  // o SRC padrao pode ter mudado em Opcoes desde a ultima vez
  updateCrsBadge();
  updateRecentProjects();
  QWidget::showEvent( event );
}

void ImanHomePage::updateCrsBadge()
{
  const QgsSettings settings;
  const QgsCoordinateReferenceSystem crs( settings.value( QStringLiteral( "/projections/defaultProjectCrs" ), Qgis::geographicCrsAuthId(), QgsSettings::App ).toString() );
  if ( !crs.isValid() )
  {
    mCrsBadge->clear();
    return;
  }
  const int size = mCrsBadge->fontMetrics().height();
  const QString icon = QStringLiteral( "<img src=\":/images/themes/default/mIconProjectionEnabled.svg\" width=\"%1\" height=\"%1\">&nbsp;" ).arg( size );
  mCrsBadge->setText( icon + QStringLiteral( "%1 %2 %3" ).arg( crs.authid(), QString( MIDDLE_DOT ), crs.description() ).toHtmlEscaped() );
}

void ImanHomePage::updateRecentProjects()
{
  const bool empty = !mRecentProjectsModel || mRecentProjectsModel->rowCount() == 0;
  mRecentProjectsView->setVisible( !empty );
  mRecentProjectsEmpty->setVisible( empty );
  if ( !empty )
    fitListToContents( mRecentProjectsView );
}

void ImanHomePage::updateTemplates()
{
  fitListToContents( mTemplatesView );
}

void ImanHomePage::fitListToContents( QListView *view )
{
  // a lista mostra todos os itens e quem rola e a pagina
  int height = 0;
  QAbstractItemModel *model = view->model();
  const int rows = model ? model->rowCount() : 0;
  for ( int row = 0; row < rows; ++row )
    height += view->sizeHintForRow( row );
  view->setFixedHeight( height + 2 * view->frameWidth() );
}

void ImanHomePage::triggerAppAction( const QString &objectName )
{
  if ( QAction *action = QgisApp::instance()->findChild<QAction *>( objectName ) )
    action->trigger();
}

void ImanHomePage::recentProjectClicked( const QModelIndex &index )
{
  if ( !index.isValid() || !( index.flags() & Qt::ItemIsEnabled ) )
    return;
  QgisApp::instance()->openProject( index.data( QgsProjectListItemDelegate::PathRole ).toString() );
}

void ImanHomePage::templateClicked( const QModelIndex &index )
{
  if ( !index.isValid() )
    return;
  // como em QgsWelcomePage::templateProjectItemActivated: sem caminho, e o projeto vazio
  if ( !index.data( QgsProjectListItemDelegate::NativePathRole ).isValid() )
    triggerAppAction( QStringLiteral( "mActionNewProject" ) );
  else
    QgisApp::instance()->fileNewFromTemplate( index.data( QgsProjectListItemDelegate::NativePathRole ).toString() );
}

void ImanHomePage::showContextMenuForProjects( QPoint point )
{
  // o mesmo menu de QgsWelcomePage::showContextMenuForProjects (fixar, desafixar, abrir pasta, atualizar, remover,
  // limpar), com os textos e as traducoes dela; fixar, remover e limpar passam pelos slots publicos da pagina nativa,
  // que segue dona do modelo e avisa o QgisApp como antes
  if ( !mWelcomePage || !mRecentProjectsModel || mRecentProjectsModel->rowCount() == 0 )
    return;

  auto trWelcome = []( const char *text ) { return QCoreApplication::translate( "QgsWelcomePage", text ); };
  const QModelIndex index = mRecentProjectsView->indexAt( point );
  QgsRecentProjectItemsModel *model = mWelcomePage->recentProjectsModel();
  QPointer<QgsWelcomePage> welcome = mWelcomePage;
  QMenu *menu = new QMenu( this );

  if ( index.isValid() )
  {
    const int row = index.row();
    const bool pin = index.data( QgsProjectListItemDelegate::PinRole ).toBool();
    QString path = index.data( QgsProjectListItemDelegate::PathRole ).toString();
    if ( path.isEmpty() )
    {
      delete menu;
      return;
    }

    QgsProjectStorage *storage = QgsApplication::projectStorageRegistry()->projectStorageFromUri( path );
    const bool enabled = index.flags() & Qt::ItemIsEnabled;

    if ( enabled )
    {
      if ( !pin )
      {
        QAction *pinAction = menu->addAction( trWelcome( "Pin to List" ) );
        connect( pinAction, &QAction::triggered, this, [welcome, row] { if ( welcome ) welcome->pinProject( row ); } );
      }
      else
      {
        QAction *unpinAction = menu->addAction( trWelcome( "Unpin from List" ) );
        connect( unpinAction, &QAction::triggered, this, [welcome, row] { if ( welcome ) welcome->unpinProject( row ); } );
      }

      if ( storage )
        path = storage->filePath( path );

      if ( !path.isEmpty() )
      {
        QAction *openFolderAction = menu->addAction( trWelcome( "Open Directory…" ) );
        connect( openFolderAction, &QAction::triggered, this, [path] {
          const QgsFocusKeeper focusKeeper;
          QgsGui::nativePlatformInterface()->openFileExplorerAndSelectFile( path );
        } );
      }
    }
    else
    {
      QAction *rescanAction = menu->addAction( trWelcome( "Refresh" ) );
      const QPersistentModelIndex persistent( index );
      connect( rescanAction, &QAction::triggered, this, [model, persistent] { if ( persistent.isValid() ) model->recheckProject( persistent ); } );

      bool showClosestPath = !storage;
      if ( storage && storage->type() == QLatin1String( "geopackage" ) )
      {
        const thread_local QRegularExpression reGpkg( "^(geopackage:)([^\?]+)\?(.+)$", QRegularExpression::CaseInsensitiveOption );
        const QRegularExpressionMatch matchGpkg = reGpkg.match( path );
        if ( matchGpkg.hasMatch() )
        {
          path = matchGpkg.captured( 2 );
          showClosestPath = true;
        }
      }
      if ( showClosestPath )
      {
        const QString closestPath = QgsFileUtils::findClosestExistingPath( path );
        QAction *openFolderAction = menu->addAction( trWelcome( "Open “%1”…" ).arg( QDir::toNativeSeparators( closestPath ) ) );
        connect( openFolderAction, &QAction::triggered, this, [closestPath] { QDesktopServices::openUrl( QUrl::fromLocalFile( closestPath ) ); } );
      }
    }
    QAction *removeAction = menu->addAction( trWelcome( "Remove from List" ) );
    connect( removeAction, &QAction::triggered, this, [welcome, row] { if ( welcome ) welcome->removeProject( row ); } );
    menu->addSeparator();
  }

  QAction *clearAction = menu->addAction( trWelcome( "Clear List" ) );
  connect( clearAction, &QAction::triggered, this, [welcome] { if ( welcome ) welcome->clearRecentProjects(); } );

  menu->popup( mRecentProjectsView->viewport()->mapToGlobal( point ) );
  connect( menu, &QMenu::aboutToHide, menu, &QMenu::deleteLater );
}
