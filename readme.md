# Comparing performance of Gren, Elm and React

_Updated Elm and React implementations taken from [lustre-labs/performance-comparison](https://github.com/lustre-labs/performance-comparison)_

This is a benchmark that tries to compare the performance of Gren, Elm and React in a fair way.

![Performance Comparison][graphs.png]

## Methodology

My goal with these benchmarks was to compare renderer performance in a realistic scenario. This means rendering each frame in full, exactly like you would if a real user was interacting with the TodoMVC app.

Browsers typically repaint their content at most 60 times per second. So if you are writing JavaScript that has it changing the content 120 times per second, half of that work is wasted. Furthermore, you want your repaints to be at very even intervals so that the 60 repaints align with the 60hz of most monitors. To get the smoothest animations possible, you need to sync up with this.

So `requestAnimationFrame` was introduced. It lets you say &ldquo;here is a function that modifies the DOM, but I want the browser to make the changes whenever *it* thinks it is a good idea.&rdquo; That means the repaints get smoothed out to 60 FPS no matter how crazy your JS happens to be.

Say you get events coming in extremely quickly, and you get four events within a single frame. A naive use of `requestAnimationFrame` would just schedule them all to happen in sequence. So you would build all four virtual DOMs, diff them against each other in sequence, and show the final result to the user. We can do better though! We can just skip three of those frames entirely. Instead diff the current virtual DOM against the latest virtual DOM. The end result is exactly the same (the user sees the final result) but we skipped 75% of the work!

Elm and Gren does this optimization by default. React doesn't, and it is not their fault. If you are writing code in JavaScript (or TypeScript) this optimization is not safe at all. This optimization is all about rescheduling and skipping work, and in JavaScript, that work may have some observable effect on the rest of your program. Say you mutate your some state from the `view`. Simple. Common. There are two ways this can go wrong:

  1. Using `requestAnimationFrame` means this mutation happens *later* than you expected. In the meantime, you may need to do other work that depends on that mutation having already happened. So if another event comes in *before* `requestAnimationFrame` you now have a very sneaky timing bug.

  2. If you have `requestAnimationFrame` skip frames, the mutation may just *never* happen. Your application state just does not get updated correctly. This kind of bug would be truly awful to hunt down. You need a specific sequence of events to come in, one of them causing a mutation. You need them to come in so fast that they all happen within a single frame. You also need them to come in a specific order such that the event that causes mutation is one of the ones that gets dropped. This could be the definition of a [Heisenbug](https://en.wikipedia.org/wiki/Heisenbug) and I do not think I could create a more difficult bug on purpose.

In both cases, the fundamental problem is that mutation is possible in your `view` code in JavaScript or TypeScript. A programmer *can* mutate something, and nothing that the React team does will change this fact. Given that, I personally think it would be crazy for them to have this kind of optimization turned on by default. In that world, using React would almost guarantee that you see these bugs in practice.

To bring it back to these benchmarks, the simulated user input comes in really fast, so if I let Elm/Gren use `requestAnimationFrame` like it normally would, it would end up skipping tons of frames. That would look good, but if those events were created by a real human being, I doubt *any* of them would happen within a single frame. So in the more realistic scenario, this optimization is not going to have an impact on events that are as slow as human beings. So yes, it is really nice that Elm and Gren has this by default, and it definitely makes sense to take that into account when deciding if you want to use Elm/Gren, but it would not be fair for this benchmark.


## Building it Yourself

If you want to fork this repo and try things out, you need to run something like this:

```bash
cd src
elm make Picker.elm --output=picker.js
```

And then navigate into `implementations/*` and build the various projects. Keep in mind that the Elm and Gren builds are hand-edited to remove the `requestAnimationFrame` optimization.
