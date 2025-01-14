// NOTE:
//
//  VSCode imports should not be allowed in this module, otherwise it would contaminate the view
//

module AgdaPosition = {
  type t = {
    line: int,
    col: int,
    pos: int,
  }

  let decode: Json.Decode.decoder<t> = {
    open Json.Decode
    tuple3(int, int, int) |> map(((line, col, pos)) => {
      line: line,
      col: col,
      pos: pos,
    })
  }

  let encode: Json.Encode.encoder<t> = x => {
    open Json.Encode
    switch x {
    | {line, col, pos} => (line, col, pos) |> tuple3(int, int, int)
    }
  }
}

module AgdaInterval = {
  type t = {
    start: AgdaPosition.t,
    end_: AgdaPosition.t,
  }

  let fuse = (a, b) => {
    let start = if a.start.pos > b.start.pos {
      b.start
    } else {
      a.start
    }
    let end_ = if a.end_.pos > b.end_.pos {
      a.end_
    } else {
      b.end_
    }
    {start: start, end_: end_}
  }

  let toString = (self): string =>
    if self.start.line === self.end_.line {
      string_of_int(self.start.line) ++
      ("," ++
      (string_of_int(self.start.col) ++ ("-" ++ string_of_int(self.end_.col))))
    } else {
      string_of_int(self.start.line) ++
      ("," ++
      (string_of_int(self.start.col) ++
      ("-" ++
      (string_of_int(self.end_.line) ++ ("," ++ string_of_int(self.end_.col))))))
    }

  let decode: Json.Decode.decoder<t> = {
    open Json.Decode
    pair(AgdaPosition.decode, AgdaPosition.decode) |> map(((start, end_)) => {
      start: start,
      end_: end_,
    })
  }

  let encode: Json.Encode.encoder<t> = x => {
    open Json.Encode
    switch x {
    | {start, end_} => (start, end_) |> pair(AgdaPosition.encode, AgdaPosition.encode)
    }
  }
}

module AgdaRange = {
  type t =
    | NoRange
    | Range(option<string>, array<AgdaInterval.t>)

  let parse = %re(
    /* |  different row                    |    same row            | */
    "/^(\\S+)\\:(?:(\\d+)\\,(\\d+)\\-(\\d+)\\,(\\d+)|(\\d+)\\,(\\d+)\\-(\\d+))$/"
  )->Emacs__Parser.captures(captured => {
    open Belt
    open Belt.Option
    let flatten = xs => xs->flatMap(x => x)
    let srcFile = captured[1]->flatten
    let sameRow = captured[6]->flatten->isSome
    if sameRow {
      captured[6]
      ->flatten
      ->flatMap(int_of_string_opt)
      ->flatMap(row =>
        captured[7]
        ->flatten
        ->flatMap(int_of_string_opt)
        ->flatMap(colStart =>
          captured[8]
          ->flatten
          ->flatMap(int_of_string_opt)
          ->flatMap(colEnd => Some(
            Range(
              srcFile,
              [
                {
                  start: {
                    pos: 0,
                    line: row,
                    col: colStart,
                  },
                  end_: {
                    pos: 0,
                    line: row,
                    col: colEnd,
                  },
                },
              ],
            ),
          ))
        )
      )
    } else {
      captured[2]
      ->flatten
      ->flatMap(int_of_string_opt)
      ->flatMap(rowStart =>
        captured[3]
        ->flatten
        ->flatMap(int_of_string_opt)
        ->flatMap(colStart =>
          captured[4]
          ->flatten
          ->flatMap(int_of_string_opt)
          ->flatMap(rowEnd =>
            captured[5]
            ->flatten
            ->flatMap(int_of_string_opt)
            ->flatMap(colEnd => Some(
              Range(
                srcFile,
                [
                  {
                    start: {
                      pos: 0,
                      line: rowStart,
                      col: colStart,
                    },
                    end_: {
                      pos: 0,
                      line: rowEnd,
                      col: colEnd,
                    },
                  },
                ],
              ),
            ))
          )
        )
      )
    }
  })

  let fuse = (a: t, b: t): t => {
    open AgdaInterval

    let mergeTouching = (l, e, s, r) =>
      Belt.List.concat(Belt.List.concat(l, list{{start: e.start, end_: s.end_}}), r)

    let rec fuseSome = (s1, r1, s2, r2) => {
      let r1' = Util.List.dropWhile(x => x.end_.pos <= s2.end_.pos, r1)
      helpFuse(r1', list{AgdaInterval.fuse(s1, s2), ...r2})
    }
    and outputLeftPrefix = (s1, r1, s2, is2) => {
      let (r1', r1'') = Util.List.span(s => s.end_.pos < s2.start.pos, r1)
      Belt.List.concat(Belt.List.concat(list{s1}, r1'), helpFuse(r1'', is2))
    }
    and helpFuse = (a: Belt.List.t<AgdaInterval.t>, b: Belt.List.t<AgdaInterval.t>) =>
      switch (a, Belt.List.reverse(a), b, Belt.List.reverse(b)) {
      | (list{}, _, _, _) => a
      | (_, _, list{}, _) => b
      | (list{s1, ...r1}, list{e1, ...l1}, list{s2, ...r2}, list{e2, ...l2}) =>
        if e1.end_.pos < s2.start.pos {
          Belt.List.concat(a, b)
        } else if e2.end_.pos < s1.start.pos {
          Belt.List.concat(b, a)
        } else if e1.end_.pos === s2.start.pos {
          mergeTouching(l1, e1, s2, r2)
        } else if e2.end_.pos === s1.start.pos {
          mergeTouching(l2, e2, s1, r1)
        } else if s1.end_.pos < s2.start.pos {
          outputLeftPrefix(s1, r1, s2, b)
        } else if s2.end_.pos < s1.start.pos {
          outputLeftPrefix(s2, r2, s1, a)
        } else if s1.end_.pos < s2.end_.pos {
          fuseSome(s1, r1, s2, r2)
        } else {
          fuseSome(s2, r2, s1, r1)
        }
      | _ => failwith("something wrong with Range::fuse")
      }
    switch (a, b) {
    | (NoRange, r2) => r2
    | (r1, NoRange) => r1
    | (Range(f, r1), Range(_, r2)) =>
      Range(f, helpFuse(Belt.List.fromArray(r1), Belt.List.fromArray(r2))->Belt.List.toArray)
    }
  }

  open Belt
  let toString = (self: t): string =>
    switch self {
    | NoRange => ""
    | Range(Some(filepath), []) => filepath
    | Range(None, xs) =>
      switch (xs[0], xs[Array.length(xs) - 1]) {
      | (Some(first), Some(last)) => AgdaInterval.toString({start: first.start, end_: last.end_})
      | _ => ""
      }
    | Range(Some(filepath), xs) =>
      switch (xs[0], xs[Array.length(xs) - 1]) {
      | (Some(first), Some(last)) =>
        filepath ++ ":" ++ AgdaInterval.toString({start: first.start, end_: last.end_})
      | _ => ""
      }
    }

  let decode: Json.Decode.decoder<t> = Util.Decode.sum(x => {
    open Json.Decode
    switch x {
    | "Range" =>
      Contents(
        pair(optional(string), array(AgdaInterval.decode)) |> map(((source, intervals)) => Range(
          source,
          intervals,
        )),
      )
    | "NoRange" => TagOnly(NoRange)
    | tag => raise(DecodeError("[Agda.Range] Unknown constructor: " ++ tag))
    }
  })

  let encode: Json.Encode.encoder<t> = x => {
    open Json.Encode
    switch x {
    | Range(source, intervals) =>
      object_(list{
        ("tag", string("Range")),
        ("contents", (source, intervals) |> pair(nullable(string), array(AgdaInterval.encode))),
      })
    | NoRange => object_(list{("tag", string("NoRange"))})
    }
  }
}

// NOTE: This is not related to VSCode or Agda
// NOTE: eliminate this
module Interval = {
  type t = (int, int)

  let contains = (interval, offset) => {
    let (start, end_) = interval
    start <= offset && offset <= end_
  }

  let decode = Json.Decode.pair(Json.Decode.int, Json.Decode.int)
  let encode = Json.Encode.pair(Json.Encode.int, Json.Encode.int)
}
