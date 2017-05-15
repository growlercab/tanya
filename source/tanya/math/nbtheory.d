/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Number Theory.
 *
 * Copyright: Eugene Wissner 2017.
 * License: $(LINK2 https://www.mozilla.org/en-US/MPL/2.0/,
 *                  Mozilla Public License, v. 2.0).
 * Authors: $(LINK2 mailto:info@caraus.de, Eugene Wissner)
 */
module tanya.math.nbtheory;

import std.algorithm.mutation;
import tanya.math;

void inv(ref Integer z, ref Integer a)
{
    Integer y2, quotient;

    auto y = Integer(1);
    auto y1 = Integer(1);

    auto i = a;
    auto j = z;
    if (z < 0)
    {
        j %= a;
        // force positive remainder always
        j = abs(move(j));
        j -= a;
    }

    while (j != 0)
    {
        auto remainder = i;
        i = j;
        quotient = abs(remainder / j);
        remainder %= j;

        quotient *= y1; // quotient = y1 * quotient
        y = y2;
        y -= quotient; // y = y2 - (y1 * quotient)

        j = remainder;
        y2 = y1;
        y1 = y;
    }

    z = y2;
    z %= a; // inv_z = y2 % a

    if (z < 0)
    {
        z = abs(move(z));
        z -= a;
        z = abs(move(z));
    }
}
