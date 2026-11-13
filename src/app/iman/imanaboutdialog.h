/***************************************************************************
    imanaboutdialog.h
    ---------------------
    IMAN Terra: "Sobre o IMAN Terra", aberto pelo item Sobre do menu Ajuda no
    lugar do QgsAbout (fatia 059, prototipo). O QgsAbout nao muda e abre pelo
    botao "Sobre o QGIS" deste dialogo. Desenho e textos do Sobre da distro
    congelada (iman-qgis-distro-agent, app/profile-template/iman-distro/python/
    plugins/iman_brand/sobre.py, commit 59ac0ce), refeitos em C++.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef IMANABOUTDIALOG_H
#define IMANABOUTDIALOG_H

#include <QDialog>

class QTextBrowser;

class ImanAboutDialog : public QDialog
{
    Q_OBJECT

  public:
    explicit ImanAboutDialog( QWidget *parent = nullptr );

    /**
     * Versao do produto com o commit do build ("0.4.0 . ee83c9c7b7"); sem o commit, so a versao.
     */
    static QString displayVersion();

    /**
     * Creditos do QGIS (BL-1, BL-2): tres frases, em linhas separadas ou, com \a footer, numa linha so,
     * precedida de "powered by QGIS", para o rodape da pagina inicial.
     */
    static QString qgisCreditsText( bool footer = false );

    /**
     * Caminho do THIRD_PARTY_NOTICES.md que o produto entrega na raiz da instalacao, dois niveis acima do
     * prefixo (apps/qgis-ltr).
     */
    static QString noticesPath();

  signals:
    //! O usuario pediu o "Sobre" do QGIS (o QgsAbout de sempre).
    void aboutQgisRequested();

  private:
    QTextBrowser *mNotices = nullptr;
};

#endif // IMANABOUTDIALOG_H
