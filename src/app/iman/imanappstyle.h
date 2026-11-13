/***************************************************************************
    imanappstyle.h
    ---------------------
    IMAN Terra: o raio das quinas so do QPushButton (fatia 066; adendo de
    2026-11-13 ao D-IMAN-040), por um estilo do Qt em C++, nunca por folha
    de estilo. O estilo da aplicacao passa a ser este, no lugar do
    QgsAppStyle do QGIS (do qual herda tudo): ele so redesenha o painel do
    botao (PE_PanelButtonCommand) quando o widget e um QPushButton, com o
    desenho do Fusion e o raio da marca (IMAN_BUTTON_RADIUS_PX, do
    brand.json); todo outro widget que passa pelo mesmo painel (botao de
    ferramenta, botao de cor) segue com o desenho do Fusion. So com o tema
    default do QGIS e o estilo fusion.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef IMANAPPSTYLE_H
#define IMANAPPSTYLE_H

#include "qgis_app.h"
#include "qgsproxystyle.h"

#include <QString>

class APP_EXPORT ImanAppStyle : public QgsAppStyle
{
    Q_OBJECT

  public:
    /**
     * O QgsAppStyle de \a base (o nome do estilo do Qt, como no QgsAppStyle), com o raio da marca no QPushButton se
     * \a uiTheme (o valor de UI/UITheme) da o tema default do QGIS e a base e o fusion. O objectName segue
     * "QgsAppStyle", que o QgsProxyStyle do QGIS procura para copiar o estilo da aplicacao.
     */
    ImanAppStyle( const QString &base, const QString &uiTheme );

    void drawPrimitive( PrimitiveElement element, const QStyleOption *option, QPainter *painter, const QWidget *widget = nullptr ) const override;

    //! Verdadeiro quando o raio da marca vale (tema default e base fusion).
    bool roundsPushButtons() const { return mRoundPushButtons; }

    /**
     * Um ImanAppStyle novo, com a mesma base e o mesmo tema. Quem chama pelo tipo QgsAppStyle (o QgsProxyStyle) recebe
     * o clone do QgsAppStyle, porque ele nao e virtual: sem o raio, o desenho do Fusion.
     */
    QProxyStyle *clone();

  private:
    void drawPushButtonPanel( const QStyleOption *option, QPainter *painter ) const;

    QString mUiTheme;
    bool mRoundPushButtons = false;
};

#endif // IMANAPPSTYLE_H
