open BsMocha.Mocha
open Js.Promise

open Test__Util

open Belt

// [Int] -> String -> [SExpression]
let parseSExpression = (breakpoints, input) => {
  open Parser.Incr.Gen

  let output = ref([])

  let parser = Parser.SExpression.makeIncr(x =>
    switch x {
    | Yield(Error((errNo, raw))) =>
      Assert.fail(
        "Failed when parsing S-expression: " ++ Parser.Error.toString(SExpression(errNo, raw)),
      )
    | Yield(Ok(a)) => Js.Array.push(a, output.contents) |> ignore
    | Stop => ()
    }
  )

  input
  ->Js.String.trim
  ->Strings.breakInput(breakpoints)
  ->Array.map(Parser.split)
  ->Array.concatMany
  ->Array.forEach(Parser.Incr.feed(parser))

  output.contents
}

describe("when parsing S-expressions as a whole", () =>
  Golden.getGoldenFilepathsSync(
    "../../../../test/tests/Parser/SExpression",
  )->Array.forEach(filepath =>
    BsMocha.Promise.it("should golden test " ++ filepath, () =>
      Golden.readFile(filepath) |> then_(raw =>
        raw
        ->Golden.map(parseSExpression([]))
        ->Golden.map(Strings.serializeWith(Parser.SExpression.toString))
        ->Golden.compare
      )
    )
  )
)

describe("when parsing S-expressions incrementally", () =>
  Golden.getGoldenFilepathsSync(
    "../../../../test/tests/Parser/SExpression",
  )->Array.forEach(filepath =>
    BsMocha.Promise.it("should golden test " ++ filepath, () =>
      Golden.readFile(filepath) |> then_(raw =>
        raw
        ->Golden.map(parseSExpression([3, 23, 171, 217, 1234, 2342, 3453]))
        ->Golden.map(Strings.serializeWith(Parser.SExpression.toString))
        ->Golden.compare
      )
    )
  )
)
