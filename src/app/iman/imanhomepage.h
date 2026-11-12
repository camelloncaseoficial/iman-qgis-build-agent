/***************************************************************************
    imanhomepage.h
    ---------------------
    IMAN Terra: pagina inicial da marca no lugar da pagina de boas-vindas do
    QGIS (fatia 059, prototipo). Desenho e textos da pagina inicial da distro
    congelada (iman-qgis-distro-agent, app/profile-template/iman-distro/python/
    plugins/iman_brand/dashboard.py, commit 59ac0ce), refeitos em C++.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef IMANHOMEPAGE_H
#define IMANHOMEPAGE_H

#include <QAbstractItemModel>
#include <QFrame>
#include <QPointer>
#include <QStyledItemDelegate>
#include <QWidget>

class QLabel;
class QListView;
class QStandardItemModel;
class QgsWelcomePage;

/**
 * Cartao clicavel da pagina inicial (uma acao que o QGIS ja tem).
 */
class ImanHomeCard : public QFrame
{
    Q_OBJECT

  public:
    ImanHomeCard( const QString &iconPath, const QString &title, const QString &subtitle, QWidget *parent = nullptr );

  signals:
    void clicked();

  protected:
    void mouseReleaseEvent( QMouseEvent *event ) override;
    void keyPressEvent( QKeyEvent *event ) override;
};

/**
 * Item de projeto (recente ou modelo): titulo, caminho e o alfinete, com as
 * cores da paleta e raio 2px.
 */
class ImanProjectItemDelegate : public QStyledItemDelegate
{
    Q_OBJECT

  public:
    explicit ImanProjectItemDelegate( bool showPath, QObject *parent = nullptr );
    void paint( QPainter *painter, const QStyleOptionViewItem &option, const QModelIndex &index ) const override;
    QSize sizeHint( const QStyleOptionViewItem &option, const QModelIndex &index ) const override;

  private:
    bool mShowPath = true;
};

/**
 * Pagina inicial do IMAN Terra, no indice 1 do mCentralContainer do QgisApp.
 *
 * Os recentes sao os do QGIS: o mesmo modelo da QgsWelcomePage, que continua
 * existindo (fora da tela) e segue dona do modelo e dos slots de fixar,
 * remover e limpar, ligados ao QgisApp como antes.
 */
class ImanHomePage : public QWidget
{
    Q_OBJECT

  public:
    explicit ImanHomePage( QgsWelcomePage *welcomePage, QWidget *parent = nullptr );

  protected:
    void showEvent( QShowEvent *event ) override;

  private slots:
    void updateRecentProjects();
    void updateTemplates();
    void recentProjectClicked( const QModelIndex &index );
    void templateClicked( const QModelIndex &index );
    void showContextMenuForProjects( QPoint point );

  private:
    void updateCrsBadge();
    static void triggerAppAction( const QString &objectName );
    static void fitListToContents( QListView *view );

    QPointer<QgsWelcomePage> mWelcomePage;
    QPointer<QAbstractItemModel> mRecentProjectsModel;
    QStandardItemModel *mTemplateProjectsModel = nullptr;
    QListView *mRecentProjectsView = nullptr;
    QLabel *mRecentProjectsEmpty = nullptr;
    QListView *mTemplatesView = nullptr;
    QLabel *mCrsBadge = nullptr;
};

#endif // IMANHOMEPAGE_H
