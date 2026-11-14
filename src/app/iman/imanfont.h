/***************************************************************************
    imanfont.h
    ---------------------
    IMAN Terra: a fonte da marca na interface inteira (fatia 067, adendo de
    2026-11-14 ao D-IMAN-040 e emenda de 2026-11-14 ao D-IMAN-026). Os TTF
    estaticos da familia da marca (IMAN_FONT_FAMILY, do brand.json) vao
    compilados no qgis_app (imanfonts.qrc), registrados so para o processo
    pelo QFontDatabase e aplicados na fonte da aplicacao com o tamanho que ela
    ja tem, sem folha de estilo, e so quando o tema em uso e o default do
    QGIS. Nada e instalado no Windows e nada e gravado no perfil.
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef IMANFONT_H
#define IMANFONT_H

#include "qgis_app.h"

#include <QString>

class APP_EXPORT ImanFont
{
  public:
    /**
     * Se \a uiTheme (o valor de UI/UITheme) da o tema default do QGIS (a regra de ImanPalette::isDefaultTheme),
     * registra os TTF da marca do recurso compilado (:/iman/fonts) e, se todos registrarem e a familia da marca
     * aparecer entre as registradas, poe essa familia na fonte da aplicacao mantendo o tamanho atual
     * (QApplication::setFont). Se algum registro falhar, desfaz os registros feitos, deixa a fonte do sistema e
     * uma mensagem no log; nunca derruba o programa. Chamar antes do bloco do main.cpp que aplica a fonte escolhida
     * pelo usuario em Opcoes (/app/fontFamily e /app/fontPointSize), para que a escolha dele continue mandando.
     * Devolve se a fonte da marca foi aplicada.
     */
    static bool apply( const QString &uiTheme );
};

#endif // IMANFONT_H
